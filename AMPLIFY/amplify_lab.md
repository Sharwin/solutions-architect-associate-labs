# AWS Amplify Static Web Hosting Lab

This guide details how to deploy a static website to AWS Amplify using Terraform for infrastructure provisioning and a custom shell script for deployment.

## Prerequisites

Ensure you have the following tools installed:
- **Terraform**: For Infrastructure as Code.
- **AWS CLI**: Configured with appropriate permissions.
- **jq**: For parsing JSON output in the deployment script.
- **zip**: For archiving the source code.

## Step 1: Infrastructure Provisioning

We use Terraform to create the Amplify App and Branch.

**File:** `main.tf`
Defines the `aws_amplify_app` and `aws_amplify_branch` resources.

**Command:**
Initialize and apply the Terraform configuration.

```bash
terraform init
terraform apply -auto-approve
```

**Example Output:**
```text
aws_amplify_app.lab_app: Creating...
aws_amplify_app.lab_app: Creation complete after 1s [id=dz2v3vwyn8nnn]
aws_amplify_branch.main: Creating...
aws_amplify_branch.main: Creation complete after 1s [id=dz2v3vwyn8nnn/main]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

amplify_app_id = "dz2v3vwyn8nnn"
amplify_branch_name = "main"
amplify_default_domain = "https://main.dz2v3vwyn8nnn.amplifyapp.com"
aws_region = "us-east-1"
```

## Step 2: Application Deployment

We use a shell script to zip the source code and deploy it to the created Amplify app.

**File:** `deploy.sh`
1. Retrieves App ID and Branch Name from Terraform outputs.
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
Deploying to Amplify App: dz2v3vwyn8nnn, Branch: main
Creating deployment artifact...
  adding: index.html (deflated 59%)
  adding: style.css (deflated 64%)
Creating deployment...
Job ID: 1
Uploading artifact...
Starting deployment...
{
    "jobSummary": {
        "jobArn": "arn:aws:amplify:us-east-1:277411033138:apps/dz2v3vwyn8nnn/branches/main/jobs/0000000001",
        "jobId": "1",
        "status": "PENDING"
    }
}
Deployment started! Check the AWS Console or wait for it to complete.
URL: https://main.dz2v3vwyn8nnn.amplifyapp.com
```

## Step 3: Verification

Verify the application is running by accessing the URL.

**Command:**
```bash
curl -I https://main.dz2v3vwyn8nnn.amplifyapp.com
```

**Example Output:**
```text
HTTP/2 200 
content-type: text/html
content-length: 1421
server: AmazonS3
...
```

## Cleanup

To remove all resources created by this lab:

```bash
terraform destroy -auto-approve
```
