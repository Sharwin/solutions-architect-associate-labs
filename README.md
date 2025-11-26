# AWS Certified Solutions Architect - Associate (SAA-C03) Hands-on Labs

This repository contains a collection of hands-on labs designed to help you prepare for the **AWS Certified Solutions Architect - Associate (SAA-C03)** exam. Each lab focuses on specific AWS services and architectural patterns, providing practical experience with Infrastructure as Code (IaC), serverless technologies, and container orchestration.

## 🎯 Objectives

*   **Hands-on Experience**: Gain practical skills by deploying real-world scenarios.
*   **Exam Preparation**: Understand key concepts, limits, and best practices tested in the SAA-C03 exam.
*   **Infrastructure as Code**: Learn to provision resources using **AWS CloudFormation** and **Terraform** (where applicable).

## 🛠️ Prerequisites

To successfully run these labs, you should have the following tools installed and configured:

*   **AWS CLI** (v2): Configured with appropriate IAM permissions.
*   **Python 3.x**: For running test scripts and Lambda functions.
*   **kubectl**: For the EKS lab.
*   **Git**: To clone and manage this repository.

## 🧪 Available Labs

| Lab Directory | Service(s) | Description | Key Concepts |
| :--- | :--- | :--- | :--- |
| **[AMPLIFY](./AMPLIFY)** | AWS Amplify | Deploy a static website using CloudFormation and custom deployment scripts. | Static Hosting, CI/CD, CloudFormation |
| **[ECS](./ECS)** | Amazon ECS (Fargate) | Deploy a highly available WordPress application using Fargate and ALB. | Containers, Fargate, ALB, VPC Networking |
| **[EKS](./EKS)** | Amazon EKS | Deploy a production-ready Kubernetes cluster and WordPress application. | Kubernetes, Managed Node Groups, PVC/EBS, IAM Roles |
| **[SFN](./SFN)** | AWS Step Functions | Build a serverless order processing workflow with error handling. | State Machines, Lambda Integration, Error Handling (Retry/Catch) |
| **[SNS](./SNS)** | Amazon SNS | Build an e-commerce notification system with Fanout pattern. | Pub/Sub, Fanout, Message Filtering, SQS Integration |
| **[SQS](./SQS)** | Amazon SQS | Implement an order processing system using Standard and FIFO queues. | Decoupling, FIFO vs. Standard, Dead Letter Queues (DLQ), Long Polling |

## 🚀 Getting Started

1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/Sharwin/solutions-architect-associate-labs.git
    cd solutions-architect-associate-labs
    ```

2.  **Choose a Lab**: Navigate to the specific lab directory (e.g., `cd ECS`).

3.  **Follow the Instructions**: Each directory contains a detailed `README.md` with specific deployment steps, verification commands, and cleanup instructions.

## ⚠️ Important Note on Costs

These labs create real AWS resources. While many resources may fall within the AWS Free Tier, some (like NAT Gateways, ALBs, or EKS clusters) **will incur costs**.

**ALWAYS** follow the **Cleanup** section in each lab's README to delete resources when you are finished.

## 🎓 Exam Tips

Look for the **SAA-C03 Exam Tips** section in each lab's documentation. These sections highlight specific details often tested in the exam, such as:
*   Pricing models (e.g., Fargate vs. EC2).
*   Limits and Quotas.
*   High Availability and Fault Tolerance patterns.
*   Security best practices.

---
*Happy Cloud Computing!*
