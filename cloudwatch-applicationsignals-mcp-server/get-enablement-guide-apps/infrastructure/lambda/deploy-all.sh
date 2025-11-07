#!/bin/bash

# Get the current directory (should be lambda)
CDK_DIR=$(pwd)

# Bootstrap account
npm install -g aws-cdk
# npx cdk bootstrap aws://$(aws sts get-caller-identity --query Account --output text)/$(aws configure get region)
npx cdk bootstrap aws://$(aws sts get-caller-identity --query Account --output text)/us-east-1 &
npx cdk bootstrap aws://$(aws sts get-caller-identity --query Account --output text)/us-east-2 &
npx cdk bootstrap aws://$(aws sts get-caller-identity --query Account --output text)/us-west-1 &
npx cdk bootstrap aws://$(aws sts get-caller-identity --query Account --output text)/us-west-2 &

wait

# Builds sample apps, then deploy via CDK
cd "$CDK_DIR/node/cdk/"
./deploy.sh &

cd "$CDK_DIR/java/cdk/"
./deploy.sh &

cd "$CDK_DIR/python/cdk/"
./deploy.sh &

cd "$CDK_DIR/dotnet/cdk/"
./deploy.sh &

wait

# Builds sample apps, then deploy via terraform
# The builds of sample apps is repeated here
cd "$CDK_DIR/node/terraform/"
./deploy.sh &

cd "$CDK_DIR/java/terraform/"
./deploy.sh &

cd "$CDK_DIR/python/terraform/"
./deploy.sh &

cd "$CDK_DIR/dotnet/terraform/"
./deploy.sh &

wait

cd "$CDK_DIR/"
./show-urls.sh
