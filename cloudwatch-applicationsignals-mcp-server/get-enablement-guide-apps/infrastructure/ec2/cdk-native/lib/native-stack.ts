import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as s3_assets from 'aws-cdk-lib/aws-s3-assets';
import { Construct } from 'constructs';
import * as path from 'path';

export interface NativeAppConfig {
  appName: string;
  language: string;
  port: number;
  healthCheckPath: string;
  appPath: string;
  serviceName: string;
}

export class EC2NativeAppStack extends cdk.Stack {
  constructor(scope: Construct, id: string, config: NativeAppConfig, props?: cdk.StackProps) {
    super(scope, id, props);

    const appAsset = new s3_assets.Asset(this, 'AppCode', {
      path: path.join(__dirname, config.appPath),
    });

    const vpc = ec2.Vpc.fromLookup(this, 'DefaultVPC', {
      isDefault: true,
    });

    const role = new iam.Role(this, 'AppRole', {
      assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonS3ReadOnlyAccess'),
        iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonSSMManagedInstanceCore'),
      ],
    });

    appAsset.grantRead(role);

    const securityGroup = new ec2.SecurityGroup(this, 'AppSG', {
      vpc,
      description: `Security group for ${config.appName}`,
      allowAllOutbound: true,
    });

    const userData = ec2.UserData.forLinux();
    const installCommands = this.getInstallCommands(config.language);
    const startCommand = this.getStartCommand(config.language, config.port);

    userData.addCommands(
      '#!/bin/bash',
      'set -e',
      '',
      'yum update -y',
      ...installCommands,
      '',
      'mkdir -p /opt/app',
      `aws s3 cp s3://${appAsset.s3BucketName}/${appAsset.s3ObjectKey} /tmp/app.zip`,
      'cd /opt/app',
      'unzip /tmp/app.zip',
      'chown -R ec2-user:ec2-user /opt/app',
      '',
      ...this.getDepInstallCommands(config.language),
      '',
      `cat > /etc/systemd/system/${config.serviceName}.service << 'EOF'`,
      '[Unit]',
      `Description=${config.appName}`,
      'After=network.target',
      '',
      '[Service]',
      'Type=simple',
      'User=ec2-user',
      'WorkingDirectory=/opt/app',
      `Environment="PORT=${config.port}"`,
      `Environment="AWS_REGION=${this.region}"`,
      `ExecStart=${startCommand}`,
      'Restart=always',
      'RestartSec=10',
      '',
      '[Install]',
      'WantedBy=multi-user.target',
      'EOF',
      '',
      'systemctl daemon-reload',
      `systemctl enable ${config.serviceName}`,
      `systemctl start ${config.serviceName}`,
      '',
      'sleep 10',
      '',
      'sudo -u ec2-user bash /opt/app/generate-traffic.sh &',
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

    new cdk.CfnOutput(this, 'ServiceName', {
      value: config.serviceName,
      description: 'Systemd service name',
    });

    new cdk.CfnOutput(this, 'Language', {
      value: config.language,
      description: 'Application language',
    });
  }

  private getInstallCommands(language: string): string[] {
    switch (language) {
      case 'python':
        return ['yum install -y python3 python3-pip unzip'];
      case 'nodejs':
        return ['yum install -y nodejs npm unzip'];
      case 'java':
        return ['yum install -y java-17-amazon-corretto unzip'];
      default:
        return ['yum install -y unzip'];
    }
  }

  private getDepInstallCommands(language: string): string[] {
    switch (language) {
      case 'python':
        return [
          'cd /opt/app',
          'pip3 install -r requirements.txt'
        ];
      case 'nodejs':
        return [
          'cd /opt/app',
          'npm install --production'
        ];
      case 'java':
        return [
          'cd /opt/app',
          'mvn clean package -DskipTests'
        ];
      default:
        return [];
    }
  }

  private getStartCommand(language: string, port: number): string {
    switch (language) {
      case 'python':
        return '/usr/bin/python3 /opt/app/app.py';
      case 'nodejs':
        return '/usr/bin/node /opt/app/express-app.js';
      case 'java':
        return `/usr/bin/java -jar /opt/app/target/*.jar`;
      default:
        return '';
    }
  }
}
