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

# Set AWS environment variables
export CDK_DEFAULT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
export CDK_DEFAULT_REGION=$(aws configure get region || echo "us-east-1")

echo "Deploying to account: $CDK_DEFAULT_ACCOUNT"
echo "Deploying to region: $CDK_DEFAULT_REGION"

echo "=================================================="
echo "Deploying ECS CDK Stack: $STACK_NAME"
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

npx cdk deploy $STACK_NAME --require-approval never

echo ""
echo "=================================================="
echo "Deployment complete!"
echo "=================================================="
echo ""
echo "To check your deployed ECS services, run:"
echo "  aws ecs list-clusters --query 'clusterArns' --output table"
echo "  aws ecs list-services --cluster <cluster-name> --query 'serviceArns' --output table"
echo ""
echo "To get load balancer DNS names:"
echo "  aws elbv2 describe-load-balancers --query 'LoadBalancers[*].[LoadBalancerName,DNSName]' --output table"
