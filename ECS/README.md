# Amazon ECS Hands-on Lab: WordPress on Fargate (CloudFormation)

**Objective**: Deploy a highly available, serverless WordPress application using Amazon ECS (Fargate), Application Load Balancer (ALB), and AWS CloudFormation.

This lab is designed to help you prepare for the **AWS Certified Solutions Architect - Associate (SAA-C03)** exam by demonstrating key container orchestration concepts.

---

## 🏗️ Architecture Overview

We will deploy the following resources using a single CloudFormation template:

1.  **VPC & Networking**:
    *   A custom VPC (`10.0.0.0/16`).
    *   Two Public Subnets in different Availability Zones (High Availability).
    *   Internet Gateway and Route Tables for public access.
2.  **Application Load Balancer (ALB)**:
    *   Distributes traffic to our ECS tasks.
    *   Performs health checks on the containers.
3.  **Amazon ECS (Fargate)**:
    *   **Cluster**: A logical grouping of tasks.
    *   **Task Definition**: A blueprint for our application. We use a **Multi-Container** pattern:
        *   `wordpress`: The web server (Apache/PHP).
        *   `mysql`: The database (running as a sidecar/local container for this lab).
    *   **Service**: Maintains the desired number of tasks (1) and handles integration with the ALB.

---

## 🚀 Deployment Guide

### Prerequisites
*   AWS CLI installed and configured.
*   Terminal with internet access.

### Step 1: Deploy the Stack
Run the following command to create the infrastructure:

```bash
aws cloudformation deploy \
  --stack-name ecs-wordpress-lab \
  --template-file cloudformation/ecs-wordpress.yaml \
  --capabilities CAPABILITY_IAM
```

*Wait for the stack to reach `CREATE_COMPLETE` status.*

### Step 2: Verify Deployment
1.  **Get the Load Balancer DNS Name**:
    ```bash
    aws cloudformation describe-stacks \
      --stack-name ecs-wordpress-lab \
      --query "Stacks[0].Outputs[?OutputKey=='ALBDNSName'].OutputValue" \
      --output text
    ```
2.  **Access the Application**:
    *   Copy the DNS name from the output (e.g., `ecs-lab-alb-12345.us-east-1.elb.amazonaws.com`).
    *   Open it in your web browser.
    *   You should see the **WordPress Installation Screen**.

---

## 🎓 SAA-C03 Exam Tips

### 1. Fargate vs. EC2 Launch Type
*   **Fargate**: Serverless. You pay for vCPU/Memory per task. No EC2 instances to manage. Used in this lab for simplicity and low operational overhead.
*   **EC2 Launch Type**: You manage the underlying EC2 instances (ECS Container Instances). You pay for the EC2 instances, not the tasks. Use this if you need granular control over the OS, reserved instances, or spot instances for the cluster.

### 2. Multi-Container Task Patterns
*   **Tightly Coupled**: In this lab, `wordpress` and `mysql` run in the **same task**.
    *   They share the same **Network Namespace** (they communicate via `localhost` / `127.0.0.1`).
    *   They scale together (1 task = 1 WP + 1 DB).
*   **Sidecar Pattern**: A common use case is a logging agent or proxy (Envoy) running alongside the main app container.

### 3. Fargate Networking (`awsvpc`)
*   Every Fargate task gets its own **Elastic Network Interface (ENI)** and a private IP address from the subnet.
*   Security Groups are applied **per task**, not per host. This allows for fine-grained security (micro-segmentation).

### 4. Storage & Persistence (Critical!)
*   **Ephemeral Storage**: Fargate tasks have ephemeral storage by default. If the task stops, **all data in the MySQL database is lost**.
*   **Production Solution**:
    *   **Database**: Use **Amazon RDS** (Aurora Serverless is a great fit).
    *   **File Storage**: Use **Amazon EFS** mounted to the Fargate task for shared, persistent storage (e.g., for `wp-content/uploads`). S3 can also be used with plugins.

### 5. Load Balancer Integration
*   The ALB targets the ECS tasks using **IP Mode** (since Fargate tasks have their own IPs).
*   **Dynamic Port Mapping**: Not needed for Fargate (we use port 80), but relevant for EC2 launch type where multiple tasks might run on the same host.

---

## 🧹 Cleanup

To remove all resources and avoid future charges:

```bash
aws cloudformation delete-stack --stack-name ecs-wordpress-lab
```
