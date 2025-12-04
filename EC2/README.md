# AWS EC2 and ALB Lab: High Availability WordPress

## Overview
This lab guides you through deploying a highly available WordPress application on AWS using CloudFormation. You will provision an EC2 instance running Apache, PHP, and MariaDB, placed behind an Application Load Balancer (ALB) for traffic distribution.

## Architecture
The CloudFormation template (`lab.yaml`) deploys the following resources:
*   **VPC**: A custom Virtual Private Cloud with DNS support.
*   **Subnets**: Two public subnets in different Availability Zones (required for ALB).
*   **Internet Gateway**: Provides internet access for the VPC.
*   **Application Load Balancer (ALB)**: Distributes incoming HTTP traffic to the EC2 instance.
*   **Security Groups**:
    *   `ALBSecurityGroup`: Allows HTTP traffic (port 80) from anywhere.
    *   `EC2SecurityGroup`: Allows HTTP traffic (port 80) only from the ALB.
*   **EC2 Instance**: An Amazon Linux 2023 instance bootstrapped with:
    *   Apache Web Server (`httpd`)
    *   PHP
    *   MariaDB Database Server
    *   WordPress Application

## Prerequisites
*   AWS CLI installed and configured with appropriate credentials.
*   Basic understanding of AWS services (EC2, VPC, ALB).

## Deployment Steps

### 1. Deploy the Infrastructure
Use the AWS CLI to deploy the CloudFormation stack. This command creates all the necessary resources.

```bash
aws cloudformation deploy \
  --stack-name EC2-ALB-Lab \
  --template-file lab.yaml \
  --capabilities CAPABILITY_NAMED_IAM
```

*Wait for the stack creation to complete. This usually takes 3-5 minutes.*

### 2. Retrieve the Application URL
Once deployed, retrieve the DNS name of the Application Load Balancer.

```bash
aws cloudformation describe-stacks \
  --stack-name EC2-ALB-Lab \
  --query "Stacks[0].Outputs[?OutputKey=='WebsiteURL'].OutputValue" \
  --output text
```

### 3. Verify the Deployment
1.  Copy the URL from the previous step (e.g., `http://LabALB-xxxx.us-east-1.elb.amazonaws.com`).
2.  Open a web browser and navigate to the URL.
3.  You should see the **WordPress Installation Wizard**.

### 4. Configure WordPress
Follow the on-screen instructions to set up your WordPress site.
*   **Site Title**: Enter a title for your site.
*   **Username**: Create an admin username.
*   **Password**: Create a strong password.
*   **Email**: Enter your email address.

**Note:** The database is automatically configured. If prompted for database details (which shouldn't happen), use:
*   **Database Name**: `wordpress`
*   **Username**: `wpuser`
*   **Password**: `wppassword`
*   **Database Host**: `localhost`

## Educational Value
This lab demonstrates key AWS concepts:
*   **Infrastructure as Code (IaC)**: Defining infrastructure using CloudFormation YAML templates.
*   **Load Balancing**: Using an ALB to route traffic, which is the foundation for scaling and high availability.
*   **Security Best Practices**: Using Security Groups to implement the principle of least privilege (EC2 only accepts traffic from ALB).
*   **Bootstrapping**: Using EC2 UserData to automatically install and configure software upon instance launch.

## Cleanup
To remove all created resources and avoid future charges, delete the CloudFormation stack:

```bash
aws cloudformation delete-stack --stack-name EC2-ALB-Lab
```
