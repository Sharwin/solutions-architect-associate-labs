# AWS Amplify Static Web Hosting Lab (CloudFormation)

This guide details how to deploy a static website to AWS Amplify using CloudFormation for infrastructure provisioning and a custom shell script for deployment.

## Prerequisites

Ensure you have the following tools installed:
- **AWS CLI**: Configured with appropriate permissions.
- **jq**: For parsing JSON output in the deployment script.
- **zip**: For archiving the source code.

## Step 1: Infrastructure Provisioning

We use CloudFormation to create the Amplify App and Branch.

**File:** `template.yaml`
Defines the `AWS::Amplify::App` and `AWS::Amplify::Branch` resources.

**Command:**
Deploy the CloudFormation stack.

```bash
aws cloudformation deploy --template-file template.yaml --stack-name AmplifyLabStack --region us-east-1
```

**Example Output:**
```text
Waiting for changeset to be created..
Waiting for stack create/update to complete
Successfully created/updated stack - AmplifyLabStack
```

## Step 2: Application Deployment

We use a shell script to zip the source code and deploy it to the created Amplify app.

**File:** `deploy.sh`
1. Retrieves App ID and Branch Name from CloudFormation stack outputs.
2. Zips the `src/` directory.
3. Creates a deployment job via AWS CLI.
4. Uploads the zip file to the provided S3 URL.
5. Starts the deployment.

**Command:**
Make the script executable and run it.

```bash
chmod +x deploy.sh
./deploy.sh
```

**Example Output:**
```text
Fetching configuration from CloudFormation stack: AmplifyLabStack...
Deploying to Amplify App: d5e88omp6fshc, Branch: main
...
Deployment started! Check the AWS Console or wait for it to complete.
URL: https://main.d5e88omp6fshc.amplifyapp.com
```

## Step 3: Verification

Verify the application is running by accessing the URL.

**Command:**
```bash
curl -I https://main.d5e88omp6fshc.amplifyapp.com
```

**Example Output:**
```text
HTTP/2 200 
content-type: text/html
...
```

## Cleanup

To remove all resources created by this lab:

```bash
aws cloudformation delete-stack --stack-name AmplifyLabStack --region us-east-1
```
