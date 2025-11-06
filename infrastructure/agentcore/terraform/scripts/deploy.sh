#!/bin/bash

# Deploy AgentCore Basic Runtime Stack using Terraform
# This corresponds to the CDK deployment process

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Deploying AgentCore Basic Runtime Stack with Terraform ==="

# Check if terraform.tfvars exists, if not copy from example
if [ ! -f "$PROJECT_DIR/terraform.tfvars" ]; then
    echo "Creating terraform.tfvars from example..."
    cp "$PROJECT_DIR/terraform.tfvars.example" "$PROJECT_DIR/terraform.tfvars"
    echo "Please edit terraform.tfvars with your desired values and run this script again."
    exit 1
fi

# Navigate to project directory
cd "$PROJECT_DIR"

# Initialize Terraform
echo "Initializing Terraform..."
terraform init -upgrade

# Validate configuration
echo "Validating Terraform configuration..."
terraform validate

# Plan deployment
echo "Planning deployment..."
terraform plan

# Ask for confirmation
read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# Apply configuration
echo "Applying Terraform configuration..."
terraform apply -auto-approve

echo "=== Deployment Complete ==="
echo ""
echo "Outputs:"
terraform output

echo ""
echo "To trigger a Docker build manually:"
echo "aws codebuild start-build --project-name \$(terraform output -raw codebuild_project_name)"

echo ""
echo "To destroy the stack:"
echo "cd $PROJECT_DIR && ./scripts/destroy.sh"
