# Amazon ECS Hands-on Lab: Deploying WordPress on Fargate

**Objective**: Deploy a highly available, serverless WordPress application using Amazon ECS (Fargate), Application Load Balancer (ALB), and Terraform.

## Prerequisites
*   AWS CLI configured with Administrator permissions.
*   Terraform installed (v1.0+).
*   Terminal with `curl` installed.

---

## Step 1: Infrastructure as Code (IaC)

We have defined our infrastructure using Terraform in the `terraform/` directory.
*   **`vpc.tf`**: Creates a VPC with 2 Public Subnets for High Availability.
*   **`alb.tf`**: Provisions an Application Load Balancer to distribute traffic.
*   **`ecs.tf`**: Defines the ECS Cluster, Service, and a **Multi-Container Task Definition** (WordPress + MySQL).

---

## Step 2: Deployment

1.  Navigate to the terraform directory:
    ```bash
    cd terraform
    ```

2.  Initialize Terraform to download providers:
    ```bash
    terraform init
    ```
    **Output:**
    ```text
    Initializing the backend...
    Initializing provider plugins...
    - Finding hashicorp/aws versions matching "~> 5.0"...
    - Installing hashicorp/aws v5.100.0...
    Terraform has been successfully initialized!
    ```

3.  Apply the configuration to create resources:
    ```bash
    terraform apply -auto-approve
    ```
    **Output:**
    ```text
    aws_vpc.main: Creating...
    aws_lb.main: Creating...
    aws_ecs_cluster.main: Creating...
    ...
    Apply complete! Resources: 15 added, 0 changed, 0 destroyed.
    
    Outputs:
    alb_dns_name = "ecs-lab-alb-1445815325.us-east-1.elb.amazonaws.com"
    ```

---

## Step 3: Verify Deployment

1.  **Check the Endpoint**: Use `curl` to verify the ALB is routing traffic to WordPress.
    ```bash
    curl -I http://$(terraform output -raw alb_dns_name)
    ```
    **Output:**
    ```http
    HTTP/1.1 302 Found
    Date: Fri, 21 Nov 2025 22:03:56 GMT
    Server: Apache/2.4.65 (Debian)
    X-Powered-By: PHP/8.3.28
    Location: http://ecs-lab-alb-1445815325.us-east-1.elb.amazonaws.com/wp-admin/install.php
    ```

2.  **Browser Test**: Open the `alb_dns_name` in your browser. You should see the **WordPress Installation Screen**.

3.  **Inspect ECS Tasks**: Verify the task is running both containers.
    ```bash
    aws ecs list-tasks --cluster ecs-lab-cluster
    ```
    **Output:**
    ```json
    {
        "taskArns": [
            "arn:aws:ecs:us-east-1:277411033138:task/ecs-lab-cluster/571b679d96d14500aac02011cea0db3c"
        ]
    }
    ```

---

## Step 4: Exam Tips (SAA-C03)

*   **Multi-Container Tasks**: We used a single Task Definition with two containers (`wordpress` and `mysql`). They share the same network namespace, allowing them to communicate via `localhost` (127.0.0.1).
*   **Fargate Storage**: This lab uses **ephemeral storage**. If you stop the task, the database is wiped. For production, use **Amazon RDS** for the database and **Amazon EFS** for persistent file storage.

---

## Step 5: Cleanup

To avoid incurring future costs, destroy the infrastructure:

```bash
terraform destroy -auto-approve
```
