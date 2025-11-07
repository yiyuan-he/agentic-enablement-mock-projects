#!/bin/bash

# Get the current directory (should be lambda)
CDK_DIR=$(pwd)

cd "$CDK_DIR/node/cdk/"
npx cdk destroy --force &

cd "$CDK_DIR/java/cdk/"
npx cdk destroy --force &

cd "$CDK_DIR/python/cdk/"
npx cdk destroy --force &

cd "$CDK_DIR/dotnet/cdk/"
npx cdk destroy --force &

cd "$CDK_DIR/node/terraform/lambda/"
terraform destroy -auto-approve &

cd "$CDK_DIR/java/terraform/lambda/"
terraform destroy -auto-approve &

cd "$CDK_DIR/python/terraform/lambda/"
terraform destroy -auto-approve &

cd "$CDK_DIR/dotnet/terraform/lambda/"
terraform destroy -auto-approve &

wait
