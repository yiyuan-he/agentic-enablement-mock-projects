# Get Enablement Guide Samples

Sample infrastructure for testing the `get_enablement_guide` tool.

## Testing Requirements

**Important:** All changes to this infrastructure should be tested to ensure the IaC and sample apps work correctly.

## Deployment

### Prerequisites

- AWS CLI configured with appropriate credentials
- Node.js and npm installed
- AWS CDK CLI installed (`npm install -g aws-cdk`)

## Deploy EC2 CDK Sample

#### Step 1: Push Sample App to ECR

Before deploying the CDK stack, you must build and push the Python Flask sample application to your ECR repository.

```bash
# Navigate to the Python Flask sample app
cd sample-apps/python/flask

# Set your AWS account and region
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=$(aws configure get region)

# Create ECR repository (if it doesn't exist)
aws ecr create-repository --repository-name python-flask --region $AWS_REGION || true

# Authenticate Docker to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build and push the Docker image
docker build -t python-flask .
docker tag python-flask:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/python-flask:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/python-flask:latest
```

#### Step 2: Deploy the CDK Stack

```bash
# Navigate to the CDK directory
cd infrastructure/ec2/cdk

# Install dependencies
npm install

# Deploy the Python Flask stack
cdk deploy PythonFlaskCdkStack

# Clean up when done
cdk destroy PythonFlaskCdkStack
```

This deploys an EC2 instance running the containerized Python Flask sample application pulled from your ECR repository.

## Deploy Lambda Functions

The Lambda infrastructure includes sample functions in multiple languages (Python, Java, Node.js, .NET) with deployment options for both CDK and Terraform.

#### Prerequisites

- AWS CLI configured with appropriate credentials
- Node.js and npm installed
- AWS CDK CLI installed (`npm install -g aws-cdk`)
- Language-specific tools:
  - **Python**: Python 3.12 and pip
  - **Java**: Java 17 and Maven
  - **Node.js**: Node.js 20 and npm
  - **.NET**: .NET 8 SDK

### Quick Deployment

For any language, you can use the deployment script:

```bash
# Navigate to the language directory
cd infrastructure/lambda/{language}/cdk
./deploy.sh
```

### Manual Deployment

**Using CDK:**

```bash
# Build the function (language-specific)
cd infrastructure/lambda/{language}/sample-app

# Python
pip install -r requirements.txt -t .
zip -r function.zip . --exclude="*.pyc" "__pycache__/*"

# Java
mvn clean package

# Node.js
npm install
npm run compile

# .NET
dotnet publish -c Release -o bin/Release/net8.0/publish
cd bin/Release/net8.0/publish
zip -r function.zip .

# Deploy with CDK
cd ../cdk
npm install
npm run build
npm run deploy
```

**Using Terraform:**

```bash
# Build the function (same as above)
cd infrastructure/lambda/{language}/sample-app
# ... build steps ...

# Deploy with Terraform
cd ../terraform/lambda
terraform init
terraform apply
```

### Function Details

All Lambda functions include:
- Application Load Balancer integration
- S3 integration and logging capabilities
- Memory: 512 MB
- Timeout: 30 seconds
- Architecture: x86_64 (configurable)

**Runtime Details:**
- **Python**: Python 3.12, Handler: `lambda_function.lambda_handler`
- **Java**: Java 17, Handler: `com.example.Handler::handleRequest`
- **Node.js**: Node.js 20, Handler: `index.handler`
- **.NET**: .NET 8, Handler: `LambdaSample::LambdaSample.Function::FunctionHandler`

### Cleanup

```bash
# CDK
npm run destroy

# Terraform
terraform destroy
```

## Deploying Sample to EKS

### EKS CDK Deployment

```bash
# Navigate to the CDK directory
cd infrastructure/eks/cdk

# Install dependencies
npm install

# Deploy the Python Flask stack
cdk deploy PythonFlaskEksCdkStack

# Clean up when done
cdk destroy PythonFlaskEksCdkStack
```

This deploys an EKS Cluster with a pod running the containerized Python Flask sample application pulled from your ECR repository.

### EKS Terraform Deployment

Deploy the Python Flask sample application to Amazon EKS using Terraform.

### Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform installed
- kubectl installed
- ECR image pushed to your AWS account

### Deployment Instructions

1. **Navigate to the terraform directory:**
   ```bash
   cd infrastructure/eks/terraform
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Plan the deployment:**
   ```bash
   terraform plan -var-file="config/python-flask.tfvars"
   ```

4. **Deploy the infrastructure:**
   ```bash
   terraform apply -var-file="config/python-flask.tfvars"
   ```

5. **Configure kubectl:**
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name python-flask-eks-terraform-cluster
   ```

6. **Verify deployment:**
   ```bash
   kubectl get pods
   kubectl get services
   ```

### Clean Up

```bash
terraform destroy -var-file="config/python-flask.tfvars"
```

### What Gets Deployed

- EKS cluster with Kubernetes 1.30
- Single t3.medium worker node in public subnets
- Python Flask application deployment with traffic generator
- IAM roles with ECR, S3, and SSM permissions
- Access for Admin and ReadOnly AWS roles
