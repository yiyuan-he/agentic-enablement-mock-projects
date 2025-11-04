# ECS CDK TypeScript project

This CDK project deploys applications to Amazon ECS using Fargate.

The project creates:
- ECS Cluster with Fargate capacity
- Application Load Balancer
- ECS Services running containerized applications
- Basic logging to CloudWatch
- IAM roles for ECS task execution and basic permissions

## Configuration

Application configurations are stored in the `config/` directory. Each JSON file defines:
- Application name and service name
- ECR image name (created by `scripts/build-and-push-images.sh`)
- Port and health check settings
- Language type for monitoring

## Useful commands

* `npm run build`   compile typescript to js
* `npm run watch`   watch for changes and compile
* `npm run test`    perform the jest unit tests
* `npx cdk deploy`  deploy this stack to your default AWS account/region
* `npx cdk diff`    compare deployed stack with current state
* `npx cdk synth`   emits the synthesized CloudFormation template

## Prerequisites

1. Build and push Docker images using `scripts/build-and-push-images.sh`
2. Ensure AWS CLI is configured with appropriate permissions
3. Install dependencies: `npm install`

## Deployment

### Using the deployment script (recommended):

```bash
# Deploy specific application
./scripts/deploy.sh python-flask
./scripts/deploy.sh nodejs-express
./scripts/deploy.sh java-springboot
./scripts/deploy.sh dotnet-aspnetcore
```

### Using CDK directly:

Deploy all applications:
```bash
npx cdk deploy --all
```

Deploy specific application:
```bash
npx cdk deploy PythonFlaskEcsCdkStack
```

## Cleanup

### Using the destroy script (recommended):

```bash
# Destroy specific application
./scripts/destroy.sh python-flask
./scripts/destroy.sh nodejs-express
./scripts/destroy.sh java-springboot
./scripts/destroy.sh dotnet-aspnetcore
```

### Using CDK directly:

```bash
# Destroy all applications
npx cdk destroy --all

# Destroy specific application
npx cdk destroy PythonFlaskEcsCdkStack --force
```

**Note:** ECR repositories and Docker images are retained for future use. To also remove them, follow the commands shown after running the destroy script.
