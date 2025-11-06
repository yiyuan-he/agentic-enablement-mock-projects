#!/bin/bash

# Destroy AgentCore Basic Runtime Stack using Terraform
# This corresponds to the CDK destroy process

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Destroying AgentCore Basic Runtime Stack with Terraform ==="

# Navigate to project directory
cd "$PROJECT_DIR"

# Check if Terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "Terraform not initialized. Please run deploy.sh first."
    exit 1
fi

# Show what will be destroyed
echo "Planning destruction..."
terraform plan -destroy

# Ask for confirmation
echo ""
echo "WARNING: This will destroy all resources created by this stack!"
read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Destruction cancelled."
    exit 0
fi

# Destroy resources
echo "Destroying Terraform resources..."
terraform destroy -auto-approve

# Clean up generated files
echo "Cleaning up generated files..."
rm -f agent-code.zip
rm -f build_trigger_lambda.zip
rm -f response.json

echo "=== Destruction Complete ==="
echo "All resources have been destroyed and local files cleaned up."
