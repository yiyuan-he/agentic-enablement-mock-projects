# Get Enablement Guide Samples

## Overview
These baseline applications are used to test an AI Agent's ability to automatically enable AWS Application Signals across different platforms via our MCP enablement tool.

The testing flow is:
1. **Baseline Setup:** Deploy infrastructure without Application Signals
2. **Agent Modification:** AI Agent modifies IaC code to enable Application Signals
3. **Verification:** Redeploy and verify Application Signals is enabled

## Prerequisites
- Assumption that developers are testing using MacOS
- AWS CLI configured with appropriate credentials - we will use `us-east-1`
- Node.js and npm installed
- AWS Session Manager plugin ([installation instructions](https://docs.aws.amazon.com/systems-manager/latest/userguide/install-plugin-macos-overview.html))
- AWS CDK CLI installed (`npm install -g aws-cdk`)
- Terraform installed
- Docker and Docker Buildx (for container platforms)
- Language-specific tools:
  - **Python:** Python 3.12 and `pip`
  - **Java:** Java 17 and `mvn`
  - **Node.js:** Node.js 20 and `npm`

## Platforms

### EC2

#### Baseline Application Setup
This testing infrastructure covers two deployment approaches:
1. **Containerized (Docker)** - Applications run as Docker containers on EC2, with images pulled from Amazon ECR
2. **Non-Containerized (Native)** - Applications run directly on the EC2 instance as systemd services, with code deployed from S3 via CDK Assets

Both approaches serve as baseline setups **without** Application Signals enabled.

#### Containerized Deployment (Docker)

##### Build and Push Docker Images to ECR

```shell
# Navigate to app directory (see table below)
cd <app-directory>

# Set variables
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=$(aws configure get region || echo "us-east-1")
export ECR_REPO_NAME="<repo-name>" # See table below
export ECR_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME"

# Authenticate with ECR Public (for base images)
aws ecr-public get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin public.ecr.aws

# Authenticate Docker with ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Create ECR repository (if it doesn't exist)
aws ecr create-repository --repository-name $ECR_REPO_NAME --region $AWS_REGION 2>/dev/null || true

# Build multi-platform and push to ECR
docker buildx build --platform linux/amd64,linux/arm64 \
  -t $ECR_URI \
  --push \
  .
```

**App Directory and ECR Repository Reference:**
- Python Flask: Directory `docker-language-apps/python/flask`, Repo `python-flask`
- Python Django: Directory `docker-language-apps/python/django`, Repo `python-django`
- Node.js Express: Directory `docker-language-apps/node/express`, Repo `nodejs-express`
- Java Spring Boot: Directory `docker-language-apps/java/spring-boot`, Repo `java-springboot`

##### Deploy Containerized Infrastructure

**Using CDK:**
```shell
cd infrastructure/ec2/cdk-docker

# Install dependencies (first time only)
npm install

# Deploy specific app stack (see table below)
cdk deploy <stack-name>

# Or deploy all containerized stacks
cdk deploy --all
```

**Using Terraform:**
```shell
cd infrastructure/ec2/terraform-docker

terraform init
terraform plan -var-file="config/<app-name>.tfvars"
terraform apply -var-file="config/<app-name>.tfvars"
```

**CDK Stack Name Reference:**
- Python Flask: `PythonFlaskCdkStack`
- Python Django: `PythonDjangoCdkStack`
- Node.js Express: `NodejsExpressCdkStack`
- Java Spring Boot: `JavaSpringBootCdkStack`

**Terraform Config File Reference:**
- Python Flask: `config/python-flask.tfvars`
- Python Django: `config/python-django.tfvars`
- Node.js Express: `config/nodejs-express.tfvars`
- Java Spring Boot: `config/java-springboot.tfvars`

##### Verify Containerized Deployment

After CDK deployment completes:

###### 1. Connect to EC2 Instance

Get the instance ID from CDK output, then connect via SSM Session Manager:

```shell
aws ssm start-session --target <instance-id>
```

###### 2. Verify Docker Container

```shell
sudo docker ps
```

Expected output: Container named `PythonFlaskCdk` (or respective app name) should be running

Note: It may take a few minutes for the Docker to start on the EC2 instance.

###### 3. Verify Application Processes

```shell
sudo docker top <container-name>
```

**Expected processes running:**
- Main application process (varies by language - see table below)
- `bash generate-traffic.sh` - Traffic generation script
- `sleep 2` - Subprocess from traffic generator

**Container Names:**
- CDK: `PythonFlaskCdk`, `PythonDjangoCdk`, `NodejsExpressCdk`, `JavaSpringBootCdk`
- Terraform: `PythonFlaskTerraform`, `PythonDjangoTerraform`, `NodejsExpressTerraform`, `JavaSpringBootTerraform`

**Main Processes:**
- Python Flask: `python app.py`
- Python Django: `gunicorn`
- Node.js Express: `node express-app.js`
- Java Spring Boot: `java`

###### 4. Test Endpoints

```shell
curl http://localhost:<app-port>/health

curl http://localhost:<app-port>/api/buckets
```

**Expected response:**
- Health endpoint: `{"status":"healthy"}`
- API endpoint: `{"bucket_count": X, "buckets": ["bucket1", "bucket2", ...]}`

**Port Reference:**
- Python Flask: `5000`
- Python Django: `8000`
- Node.js Express: `8080`
- Java Spring Boot: `8080`

##### Cleanup

**Using CDK:**
```shell
cd infrastructure/ec2/cdk-docker

# Destroy specific stack (see table below)
cdk destroy <stack-name>
```

**Using Terraform:**
```shell
cd infrastructure/ec2/terraform-docker

terraform destroy -var-file="<config-file>"
```

**Optional: Delete ECR Images and Repositories**
```shell
aws ecr delete-repository --repository-name <repo-name> --region $AWS_REGION --force
```

**Stack Names:**
- Python Flask: `PythonFlaskCdkStack`
- Python Django: `PythonDjangoCdkStack`
- Node.js Express: `NodejsExpressCdkStack`
- Java Spring Boot: `JavaSpringBootCdkStack`

**Terraform Config Files:**
- Python Flask: `config/python-flask.tfvars`
- Python Django: `config/python-django.tfvars`
- Node.js Express: `config/nodejs-express.tfvars`
- Java Spring Boot: `config/java-springboot.tfvars`

**ECR Repository Names:**
- Python Flask: `python-flask`
- Python Django: `python-django`
- Node.js Express: `nodejs-express`
- Java Spring Boot: `java-springboot`

#### Non-Containzerized Deployment (Native)

For non-containerized deployments, application code from `native-language-apps/` is automatically uploaded to S3 by CDK/Terraform, then deployed to the EC2 instance and run as a systemd service. It is the same set of applications found in `docker-language-apps/`. The only difference is there are no `Dockerfile`s present, making it clear to AI Agents that this is a native deployment.

##### Deploy Non-Containerized Infrastructure

**Using CDK:**
```shell
cd infrastructure/ec2/cdk-native

# Install dependencies (first time only)
npm install

# Deploy specific app stack (see table below)
cdk deploy <stack-name>
```

**Using Terraform**:
```shell
cd infrastructure/ec2/terraform-native

terraform init
terraform plan -var-file="config/<config-file>"
terraform apply -var-file="config/<config-file>"
```

**CDK Stack Name Reference:**
- Python Flask: `PythonFlaskNativeCdkStack`
- Python Django: `PythonDjangoNativeCdkStack`
- Node.js Express: `NodejsExpressNativeCdkStack`
- Java Spring Boot: `JavaSpringBootNativeCdkStack`

**Terraform Config File Reference:**
- Python Flask: `config/python-flask.tfvars`
- Python Django: `config/python-django.tfvars`
- Node.js Express: `config/nodejs-express.tfvars`
- Java Spring Boot: `config/java-springboot.tfvars`

**App Directory Reference:**
- Python Flask: `native-language-apps/python/flask`
- Python Django: `native-language-apps/python/django`
- Node.js Express: `native-language-apps/node/express`
- Java Spring Boot: `native-language-apps/java/spring-boot`

##### Verify Non-Containerized Deployment

###### 1. Connect to EC2 Instance

Get the instance ID from deployment output, then connect via SSM Session Manager:

```shell
aws ssm start-session --target <instance-id>
```

###### 2. Verify Systemd Service

```shell
sudo systemctl status <service-name>
```

Expected output: Service should be `active (running)`

**Service Name Reference:**
- Python Flask: `python-flask-app`
- Python Django: `python-django-app`
- Node.js Express: `nodejs-express-app`
- Java Spring Boot: `java-springboot-app`

###### 3. Verify Application Processes

```shell
ps aux | grep -E "(python|node|java|generate-traffic)" | grep -v grep
```

**Expected processes running:**
- Main application process
- Traffic generation script (`generate-traffic.sh`)

###### 4. Check Application Logs

```shell
sudo journalctl -u <service-name> -f
```

This shows real-time logs from the systemd service.

**Service Name Reference:**
- Python Flask: `python-flask-app`
- Python Django: `python-django-app`
- Node.js Express: `nodejs-express-app`
- Java Spring Boot: `java-springboot-app`

###### 5. Test Endpoints

```shell
curl http://localhost:<app-port>/health

curl http://localhost:<app-port>/api/buckets
```

**Expected response:**
- Health endpoint: `{"status":"healthy"}`
- API endpoint: `{"bucket_count": X, "buckets": ["bucket1", "bucket2", ...]}`

**Port Reference:**
- Python Flask: `5000`
- Python Django: `8000`
- Node.js Express: `8080`
- Java Spring Boot: `8080`

##### Cleanup

**Using CDK:**
```shell
cd infrastructure/ec2/cdk-native

cdk destroy <stack-name>
```

**Using Terraform:**
```shell
cd infrastructure/ec2/terraform-native

terraform destroy -var-file="<config-file>"
```

**Stack Names:**
- Python Flask: `PythonFlaskNativeCdkStack`
- Python Django: `PythonDjangoNativeCdkStack`
- Node.js Express: `NodejsExpressNativeCdkStack`
- Java Spring Boot: `JavaSpringBootNativeCdkStack`

**Terraform Config Files:**
- Python Flask: `config/python-flask.tfvars`
- Python Django: `config/python-django.tfvars`
- Node.js Express: `config/nodejs-express.tfvars`
- Java Spring Boot: `config/java-springboot.tfvars`

### Lambda

#### Baseline Application Setup
This testing infrastructure deploys Lambda fucntions fronted by an Application Load Balancer. The Lambda functions perform S3 bucket listing operations.

Available languages: Python, Java, Node.js, .NET

#### Deploy Lambda Infrastructure

**Using CDK:**
```shell
cd infrastructure/lambda/<language>/cdk

# Install dependencies (first time only)
npm install

# Build function (language-specific - see table below)
cd ../sample-app
<build-commands>

# Deploy
cd ../cdk
npm run build
npm run deploy
```

**Using Terraform:**
```shell
cd infrastructure/lambda/<language>/terraform

# Build function (language-specific - see table below)
cd ../sample-app
<build-commands>

# Deploy
cd ../terraform/lambda
terraform init
terraform apply
```

**Language-Specific Build Commands:**

Python: 
```shell
pip install -r requirements.txt -t .
zip -r function.zip . --exclude="*.pyc" "__pycache__/*"
```
Java:
```shell
mvn clean package
```
Node.js:
```shell
npm install
npm run compile
```
.NET: 
```shell
dotnet publish -c Release -o bin/Release/net8.0/publish
cd bin/Release/net8.0/publish
zip -r ../../../../function.zip .
```

**Runtime Details:**
- **Python:** Python 3.12, **Handler:** `lambda_function.lambda_handler`
- **Java:** Java 17, **Handler:** `com.example.Handler::handleRequest`
- **Node.js:** Node.js 20, **Handler:** `index.handler`
- **.NET:** .NET 8, **Handler:** `LambdaSample::LambdaSample.Function::FunctionHandler`

#### Verify Lambda Deployment

After deployment completes, the ALB URL will be in the outputs.

**Test the endpoint:**
```shell
# Get ALB URL from CDK output or Terraform output
curl http://<alb-dns-name>
```

**Expected response:** HTML page displaying: `(Python) Hello lambda - found X buckets.` (or respective language)

#### Cleanup

**Using CDK:**
```shell
cd infrastructure/lambda/<language>/cdk

npm run destroy
```

**Using Terraform:**
```shell
cd infrastructure/lambda/<language>/lambda

terraform destroy
```

# Everything beyond this point will be re-drafted

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
