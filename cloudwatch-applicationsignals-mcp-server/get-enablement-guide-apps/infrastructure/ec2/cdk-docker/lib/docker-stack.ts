import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

export interface DockerAppConfig {
  appName: string;
  imageName: string;
  language: string;
  port: number;
  healthCheckPath: string;
}

export class EC2DockerAppStack extends cdk.Stack {
  constructor(scope: Construct, id: string, config: DockerAppConfig, props?: cdk.StackProps) {
    super(scope, id, props);

    const ecrImageUri = `${this.account}.dkr.ecr.${this.region}.amazonaws.com/${config.imageName}:latest`;

    const vpc = ec2.Vpc.fromLookup(this, 'DefaultVPC', {
      isDefault: true,
    });

    const role = new iam.Role(this, 'AppRole', {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonS3ReadOnlyAccess'),
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMManagedInstanceCore'),
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonEC2ContainerRegistryReadOnly'),
      ],
    });

    const securityGroup = new ec2.SecurityGroup(this, 'AppSG', {
      vpc,
      description: `Security group for ${config.appName}`,
      allowAllOutbound: true,
    });

    const userData = ec2.UserData.forLinux();
    userData.addCommands(
      '#!/bin/bash',
      'set -e',
      '',
      'yum update -y',
      'yum install -y docker',
      '',
      'systemctl start docker',
      'systemctl enable docker',
      'usermod -a -G docker ec2-user',
      '',
      `aws ecr get-login-password --region ${this.region} | docker login --username AWS --password-stdin ${this.account}.dkr.ecr.${this.region}.amazonaws.com`,
      '',
      `docker pull ${ecrImageUri}`,
      '',
      `docker run -d --name ${config.appName} \\`,
      `  -p ${config.port}:${config.port} \\`,
      `  -e PORT=${config.port} \\`,
      `  -e AWS_REGION=${this.region} \\`,
      `  ${ecrImageUri}`,
      '',
      'sleep 10',
      '',
      `docker exec -d ${config.appName} bash /app/generate-traffic.sh`,
      '',
      'echo "Application deployed and traffic generation started"'
    );

    const instance = new ec2.Instance(this, 'AppInstance', {
      vpc,
      instanceType: ec2.InstanceType.of(
        ec2.InstanceClass.T3,
        ec2.InstanceSize.SMALL
      ),
      machineImage: ec2.MachineImage.latestAmazonLinux2023(),
      role,
      securityGroup,
      userData,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PUBLIC,
      },
    });

    new cdk.CfnOutput(this, 'InstanceId', {
      value: instance.instanceId,
      description: 'EC2 Instance ID',
    });

    new cdk.CfnOutput(this, 'InstancePublicIP', {
      value: instance.instancePublicIp,
      description: 'EC2 Instance Public IP',
    });

    new cdk.CfnOutput(this, 'HealthCheckURL', {
      value: `http://${instance.instancePublicIp}:${config.port}${config.healthCheckPath}`,
      description: `${config.appName} Health Endpoint`,
    });

    new cdk.CfnOutput(this, 'BucketsAPIURL', {
      value: `http://${instance.instancePublicIp}:${config.port}/api/buckets`,
      description: `${config.appName} Buckets API Endpoint`,
    });

    new cdk.CfnOutput(this, 'ECRImageURI', {
      value: ecrImageUri,
      description: 'ECR image URI used',
    });

    new cdk.CfnOutput(this, 'Language', {
      value: config.language,
      description: 'Application language',
    });
  }
}
