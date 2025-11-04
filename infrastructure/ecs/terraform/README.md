# ECS Infrastructure with Terraform

This directory contains Terraform configuration to deploy containerized applications on Amazon ECS using AWS Fargate.

## Architecture

The infrastructure creates:
- ECS Cluster with Fargate launch type
- Application Load Balancer (ALB)
- ECS Service with desired count of 2 tasks
- IAM roles for ECS tasks (execution and task roles)
- Security groups for ALB and ECS service
- CloudWatch log group for application logs
- Target group with health checks

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **Docker images** pushed to ECR repositories
   - Use the `scripts/build-and-push-images.sh` script to build and push images

## Quick Start

### Deploy a specific application

```bash
# Deploy Python Flask application
./scripts/deploy.sh python-flask

# Deploy Node.js Express application
./scripts/deploy.sh nodejs-express

# Deploy Java Spring Boot application
./scripts/deploy.sh java-springboot

# Deploy .NET Core application
./scripts/deploy.sh dotnet-aspnetcore
```

### Destroy a specific application

```bash
# Destroy Python Flask application
./scripts/destroy.sh python-flask

# Destroy Node.js Express application
./scripts/destroy.sh nodejs-express
```

## Configuration Files

Each application has its own configuration file in the `config/` directory:

- `config/python-flask.tfvars` - Python Flask application
- `config/nodejs-express.tfvars` - Node.js Express application
- `config/java-springboot.tfvars` - Java Spring Boot application
- `config/dotnet-aspnetcore.tfvars` - .NET Core application

### Configuration Format

```hcl
app_name           = "python-flask-ecs-terraform"
image_name         = "python-flask"
language           = "python"
port               = 5000
app_directory      = "../../../sample-apps/python/flask"
health_check_path  = "/health"
service_name       = "python-flask-ecs-terraform"
```

## Manual Deployment

If you prefer to run Terraform commands manually:

### 1. Initialize Terraform

```bash
cd infrastructure/ecs/terraform
terraform init
```

### 2. Plan the deployment

```bash
# Set AWS region (optional, defaults to us-east-1)
export TF_VAR_aws_region="us-west-2"

# Plan with a specific config
terraform plan -var-file="config/python-flask.tfvars" -out=tfplan
```

### 3. Apply the plan

```bash
terraform apply tfplan
```

### 4. View outputs

```bash
terraform output
```

### 5. Destroy when done

```bash
terraform destroy -var-file="config/python-flask.tfvars"
```

## Outputs

After successful deployment, Terraform will output:

- **cluster_name**: ECS cluster name
- **service_name**: ECS service name
- **load_balancer_dns**: ALB DNS name
- **health_check_url**: Health check endpoint URL
- **buckets_api_url**: Buckets API endpoint URL
- **ecr_image_uri**: ECR image URI used
- **language**: Application programming language

## Testing the Deployment

Once deployed, you can test the endpoints:

```bash
# Health check
curl http://<load-balancer-dns>:<port>/health

# Buckets API
curl http://<load-balancer-dns>:<port>/api/buckets
```

Example:
```bash
curl http://python-flask-ecs-terraform-alb-123456789.us-west-2.elb.amazonaws.com:5000/health
curl http://python-flask-ecs-terraform-alb-123456789.us-west-2.elb.amazonaws.com:5000/api/buckets
```

## Infrastructure Components

### Networking
- Uses default VPC and public subnets
- Creates security groups for ALB (internet-facing) and ECS service
- ALB is internet-facing, ECS tasks are in public subnets with public IPs

### ECS Configuration
- **Launch Type**: Fargate
- **CPU**: 512 (0.5 vCPU)
- **Memory**: 1024 MB (1 GB)
- **Desired Count**: 2 tasks
- **Health Check**: HTTP health check on the configured path

### IAM Roles
- **Task Execution Role**: Allows ECS to pull images and write logs
- **Task Role**: Allows application to access AWS services (S3 read-only)

### Monitoring
- CloudWatch log group with 7-day retention
- Application logs streamed to CloudWatch

## Customization

### Adding a New Application

1. Create a new `.tfvars` file in the `config/` directory
2. Update the deploy and destroy scripts to include the new application
3. Ensure the Docker image is available in ECR

### Modifying Resources

Edit the Terraform files:
- `main.tf` - Main infrastructure resources
- `variables.tf` - Input variables
- `outputs.tf` - Output values

## Troubleshooting

### Common Issues

1. **Image not found**: Ensure Docker images are pushed to ECR
2. **Permission denied**: Check AWS credentials and IAM permissions
3. **Resource conflicts**: Use unique naming or different regions

### Debugging

```bash
# Check ECS service status
aws ecs describe-services --cluster <cluster-name> --services <service-name>

# Check task status
aws ecs list-tasks --cluster <cluster-name> --service-name <service-name>

# View logs
aws logs describe-log-groups --log-group-name-prefix "/ecs/"
```

## Comparison with CDK Version

This Terraform version provides the same functionality as the CDK version:
- Same architecture and resource configuration
- Equivalent IAM roles and permissions
- Same networking setup
- Compatible configuration format (converted from JSON to HCL)
- Similar deployment and management scripts

Key differences:
- Uses `.tfvars` files instead of `.json` config files
- Terraform state management instead of CloudFormation
- HCL syntax instead of TypeScript
- Manual initialization required (`terraform init`)
