#!/bin/bash
set -e

# Configuration
STACK_NAME="AmplifyLabStack"
AWS_REGION="us-east-1"

echo "Fetching configuration from CloudFormation stack: $STACK_NAME..."

APP_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $AWS_REGION --query "Stacks[0].Outputs[?OutputKey=='AmplifyAppId'].OutputValue" --output text)
BRANCH_NAME=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $AWS_REGION --query "Stacks[0].Outputs[?OutputKey=='AmplifyBranchName'].OutputValue" --output text)
DOMAIN=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $AWS_REGION --query "Stacks[0].Outputs[?OutputKey=='AmplifyDefaultDomain'].OutputValue" --output text)

echo "Deploying to Amplify App: $APP_ID, Branch: $BRANCH_NAME"

# Create deployment artifact
echo "Creating deployment artifact..."
cd src
zip -r ../deploy.zip ./*
cd ..

# Create a deployment
echo "Creating deployment..."
DEPLOYMENT_INFO=$(aws amplify create-deployment --app-id $APP_ID --branch-name $BRANCH_NAME --region $AWS_REGION)
JOB_ID=$(echo $DEPLOYMENT_INFO | jq -r '.jobId')
UPLOAD_URL=$(echo $DEPLOYMENT_INFO | jq -r '.zipUploadUrl')

echo "Job ID: $JOB_ID"
echo "Uploading artifact..."

# Upload the zip file using curl
curl -T deploy.zip "$UPLOAD_URL"

# Start the deployment
echo "Starting deployment..."
aws amplify start-deployment --app-id $APP_ID --branch-name $BRANCH_NAME --job-id $JOB_ID --region $AWS_REGION

echo "Deployment started! Check the AWS Console or wait for it to complete."
echo "URL: $DOMAIN"
