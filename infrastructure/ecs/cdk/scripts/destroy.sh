#!/bin/bash

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <app-name>"
    echo ""
    echo "Available apps:"
    echo "  python-flask"
    echo "  nodejs-express"
    echo "  java-springboot"
    echo "  dotnet-aspnetcore"
    echo ""
    echo "To destroy all stacks, use: npx cdk destroy --all"
    exit 1
fi

APP_NAME=$1

# Map app name to CDK stack name
case "$APP_NAME" in
    python-flask)
        STACK_NAME="PythonFlaskEcsCdkStack"
        ;;
    nodejs-express)
        STACK_NAME="NodejsExpressEcsCdkStack"
        ;;
    java-springboot)
        STACK_NAME="JavaSpringbootEcsCdkStack"
        ;;
    dotnet-aspnetcore)
        STACK_NAME="DotnetAspnetcoreEcsCdkStack"
        ;;
    *)
        echo "Error: Unknown app name: $APP_NAME"
        echo "Available apps: python-flask, nodejs-express, java-springboot, dotnet-aspnetcore"
        exit 1
        ;;
esac

# Set CDK environment variables from AWS CLI config
export CDK_DEFAULT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
export CDK_DEFAULT_REGION=$(aws configure get region || echo "us-east-1")

echo "Destroying from account: $CDK_DEFAULT_ACCOUNT"
echo "Destroying from region: $CDK_DEFAULT_REGION"

echo "=================================================="
echo "Destroying ECS CDK Stack: $STACK_NAME"
echo "=================================================="

# Get the absolute path to the ECS CDK directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
ECS_CDK_DIR="$(dirname "$SCRIPT_DIR")"

echo "Working directory: $ECS_CDK_DIR"

cd "$ECS_CDK_DIR"

# Check if node_modules exists, if not install dependencies
if [ ! -d "node_modules" ]; then
    echo "Installing npm dependencies..."
    npm install
    echo "Dependencies installed successfully!"
    echo ""
fi

npx cdk destroy $STACK_NAME --force

echo ""
echo "=================================================="
echo "Teardown complete!"
echo "=================================================="
echo ""
echo "Note: ECR repositories and images are retained for future use."
echo "To also remove ECR repositories, run:"
echo "  aws ecr describe-repositories --query 'repositories[*].repositoryName' --output table"
echo "  aws ecr delete-repository --repository-name <repo-name> --force"
