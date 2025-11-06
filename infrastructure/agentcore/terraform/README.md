# AgentCore Basic Runtime - Terraform

This Terraform configuration creates an AWS BedrockAgentCore Basic Runtime stack, equivalent to the CDK implementation in `../cdk/basic-runtime/`.

## Overview

This infrastructure provisions:

- **ECR Repository**: Stores the Docker container image for the agent
- **S3 Bucket & Object**: Stores and versions the agent source code
- **CodeBuild Project**: Builds and pushes Docker images (ARM64) to ECR
- **Lambda Function**: Triggers and waits for CodeBuild completion
- **IAM Roles & Policies**: Permissions for CodeBuild and AgentCore runtime
- **BedrockAgentCore Runtime**: The actual agent runtime that executes containers

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Agent Code    │───▶│   S3 Bucket      │───▶│  CodeBuild      │
│  (Dockerfile,   │    │  (Source Code    │    │  (ARM64 Build)  │
│   Python, etc.) │    │   Versioning)    │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ BedrockAgentCore│◀───│   Lambda         │◀───│  ECR Repository │
│    Runtime      │    │ (Build Trigger)  │    │ (Docker Images) │
│ (HTTP Protocol) │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Prerequisites

- **Terraform** >= 1.0
- **AWS CLI** configured with appropriate permissions
- **Docker** (for local testing, if needed)

## Required AWS Permissions

The deploying user/role needs permissions to create:
- ECR repositories
- S3 buckets and objects
- CodeBuild projects
- Lambda functions
- IAM roles and policies
- BedrockAgentCore agent runtimes

## Quick Start

1. **Clone and Navigate**:
   ```bash
   cd infrastructure/agentcore/terraform
   ```

2. **Configure Variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your desired values
   ```

3. **Deploy**:
   ```bash
   ./scripts/deploy.sh
   ```

4. **Build Container** (automatic, but can trigger manually):
   ```bash
   aws codebuild start-build --project-name $(terraform output -raw codebuild_project_name)
   ```

5. **Clean Up**:
   ```bash
   ./scripts/destroy.sh
   ```

## Configuration

### Terraform Variables

| Variable | Description | Default | CDK Equivalent |
|----------|-------------|---------|----------------|
| `stack_name` | Name of the stack | `BasicRuntimeStack` | CDK Stack Name |
| `aws_region` | AWS region | `us-east-1` | CDK region |
| `agent_name` | Agent runtime name | `BasicAgent` | CDK `AgentName` parameter |
| `image_tag` | Docker image tag | `latest` | CDK `ImageTag` parameter |
| `network_mode` | Network mode | `PUBLIC` | CDK `NetworkMode` parameter |

### terraform.tfvars Example

```hcl
stack_name   = "MyAgentStack"
aws_region   = "us-west-2"
agent_name   = "MyAgent"
image_tag    = "v1.0"
network_mode = "PUBLIC"
```

## Agent Code Structure

```
agent-code/
├── basic_agent.py       # Main agent logic
├── Dockerfile          # Container definition (ARM64)
├── requirements.txt    # Python dependencies
└── ...                # Additional agent files
```

## Deployment Process

1. **Initialize**: `terraform init`
2. **Plan**: `terraform plan`
3. **Apply**: `terraform apply`
4. **Auto-trigger**: Lambda function triggers CodeBuild
5. **Build**: CodeBuild creates and pushes ARM64 Docker image
6. **Runtime**: BedrockAgentCore Runtime is created with the image

## Outputs

After deployment, Terraform provides:

```bash
# View all outputs
terraform output

# Specific outputs
terraform output agent_runtime_arn
terraform output ecr_repository_url
terraform output codebuild_project_name
```

## CDK Equivalence

This Terraform implementation mirrors the CDK version:

| CDK Component | Terraform Resource |
|---------------|-------------------|
| `ecr.Repository` | `aws_ecr_repository.basic_agent` |
| `s3_assets.Asset` | `aws_s3_bucket.source_asset` + `aws_s3_object.agent_code` |
| `codebuild.Project` | `aws_codebuild_project.agent_image_build` |
| `lambda_.Function` | `aws_lambda_function.build_trigger` |
| `AgentCoreRole` | `aws_iam_role.agent_core_role` + policy |
| `bedrockagentcore.CfnRuntime` | `aws_bedrockagentcore_agent_runtime.agent_runtime` |
| `CustomResource` | `null_resource.trigger_build` (local-exec) |

## Troubleshooting

### Common Issues

1. **ECR Permissions Error**:
   ```
   Access denied while validating ECR URI
   ```
   **Solution**: Check that the AgentCore role has ECR permissions (should be automatic)

2. **Build Timeout**:
   ```
   CodeBuild build timed out
   ```
   **Solution**: Check CodeBuild logs, may need to increase Lambda timeout

3. **Lambda Invocation Failed**:
   ```
   Error invoking Lambda function
   ```
   **Solution**: Check AWS CLI configuration and Lambda function logs

### Debugging

```bash
# Check CodeBuild logs
aws logs describe-log-groups --log-group-name-prefix /aws/codebuild/

# Check Lambda logs
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/

# View ECR images
aws ecr list-images --repository-name $(terraform output -raw ecr_repository_name)
```

### Manual Build Trigger

If automatic build fails:

```bash
# Get project name
PROJECT_NAME=$(terraform output -raw codebuild_project_name)

# Trigger build manually
aws codebuild start-build --project-name $PROJECT_NAME

# Check build status
aws codebuild list-builds-for-project --project-name $PROJECT_NAME
```

## Differences from CDK

1. **Custom Resource**: Uses `null_resource` with `local-exec` instead of CDK Custom Resource
2. **Asset Handling**: Manual S3 upload instead of CDK Asset abstraction  
3. **Build Spec**: Inline JSON instead of separate buildspec.yml file
4. **Lambda Code**: Inline Python code instead of CDK Lambda Code asset

## Security Considerations

- ECR repository has image scanning enabled
- IAM roles follow least-privilege principle
- S3 bucket has versioning enabled
- All resources are tagged for governance

## Cost Optimization

- ECR repository set to `force_delete = true` for easy cleanup
- CodeBuild uses ARM64 for cost efficiency
- Lambda has 15-minute timeout to handle long builds
- S3 lifecycle policies not implemented (add if needed)

## Advanced Configuration

### Custom VPC Mode

For `PRIVATE` network mode, additional configuration needed:

```hcl
network_mode = "PRIVATE"

# Add VPC configuration (not included in basic setup)
# - VPC ID
# - Subnet IDs  
# - Security Group IDs
```

### Custom Build Image

To use different CodeBuild image:

```hcl
# In main.tf, modify:
image = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"  # x86_64 instead of ARM64
type  = "LINUX_CONTAINER"                                 # Change from ARM_CONTAINER
```

## References

- [AWS BedrockAgentCore Documentation](https://docs.aws.amazon.com/bedrock/latest/userguide/agents-agentcore.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [CDK Implementation](../cdk/basic-runtime/) (reference)

## Support

For issues:
1. Check Terraform plan/apply output
2. Review AWS CloudTrail for API errors  
3. Check CodeBuild/Lambda CloudWatch logs
4. Compare with working CDK version
