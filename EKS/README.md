# Amazon EKS Hands-On Lab (CloudFormation Edition)

## Overview
This lab demonstrates how to deploy a production-ready Amazon EKS cluster using **AWS CloudFormation**. You will deploy a WordPress application with persistent storage, simulating a real-world scenario relevant to the **AWS Certified Solutions Architect - Associate (SAA-C03)** exam.

**Key Concepts Covered:**
-   **Infrastructure as Code (IaC)**: Using CloudFormation to provision VPC, IAM Roles, and EKS.
-   **EKS Architecture**: Control Plane, Managed Node Groups, and Add-ons.
-   **Persistent Storage**: Using EBS CSI Driver for `PersistentVolumeClaims` (PVC).
-   **Networking**: VPC design for EKS (Public/Private subnets).

---

## Repository Structure

| File | Description |
| :--- | :--- |
| `eks-wordpress.yaml` | **CloudFormation Template**: Defines the VPC, IAM Roles, EKS Cluster, and Node Group. |
| `wordpress-deployment.yaml` | **Kubernetes Manifest**: Deploys WordPress, MySQL, and LoadBalancer services. |
| `cleanup.sh` | **Cleanup Script**: Automates the deletion of Kubernetes resources and the CloudFormation stack. |
| `verify_cleanup.sh` | **Verification Script**: Checks that all resources (Cluster, LBs, Stack) have been successfully deleted. |
| `README.md` | **Documentation**: This guide. |

---

## Prerequisites
-   **AWS CLI** (v2) installed and configured.
-   **kubectl** installed.
-   **Permissions**: Administrator access or sufficient permissions to create VPCs, IAM Roles, and EKS Clusters.

---

## Lab Architecture
The CloudFormation template (`eks-wordpress.yaml`) provisions:
1.  **VPC**: 10.0.0.0/16 with 2 Public and 2 Private Subnets across 2 Availability Zones.
2.  **IAM Roles**:
    -   `EKSClusterRole`: Permissions for the EKS Control Plane.
    -   `NodeGroupRole`: Permissions for Worker Nodes (including `AmazonEBSCSIDriverPolicy`).
3.  **EKS Cluster**: Version 1.28.
4.  **EKS Add-on**: `aws-ebs-csi-driver` for managing EBS volumes.
5.  **Managed Node Group**: 2 `t3.medium` instances in private subnets.

---

## Deployment Steps

### 1. Create the Infrastructure
Deploy the CloudFormation stack. This will take approximately **15-20 minutes**.

```bash
aws cloudformation create-stack \
  --stack-name eks-wordpress-lab \
  --template-body file://eks-wordpress.yaml \
  --capabilities CAPABILITY_NAMED_IAM
```

**Monitor Progress:**
```bash
aws cloudformation describe-stacks --stack-name eks-wordpress-lab --query "Stacks[0].StackStatus"
```
Wait until the status is `CREATE_COMPLETE`.

### 2. Configure kubectl
Once the stack is created, update your `kubeconfig` to interact with the cluster.

```bash
aws eks update-kubeconfig --name eks-lab-cluster-cfn --region us-east-1
```

**Verify Connection:**
```bash
kubectl get nodes
```
*Expected Output: 2 nodes in `Ready` status.*

### 3. Deploy WordPress
Deploy the WordPress application, which includes a MySQL database and a LoadBalancer.

```bash
kubectl apply -f wordpress-deployment.yaml
```

**Verify Deployment:**
```bash
kubectl get pods -n wordpress
kubectl get svc -n wordpress
```
*Wait for pods to be `Running` and the Service to have an `EXTERNAL-IP`.*

### 4. Access the Application
Retrieve the LoadBalancer URL:

```bash
kubectl get svc wordpress -n wordpress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```
Open the URL in your browser to see the WordPress setup page.

---

## 🎓 SAA-C03 Exam Tips

### 1. EKS Architecture
-   **Control Plane**: Managed by AWS. You don't see or manage the master nodes. AWS charges ~$0.10/hour for the cluster.
-   **Data Plane**: Your worker nodes (EC2 instances). In this lab, we used **Managed Node Groups**, which automates provisioning and lifecycle management of nodes.
-   **Fargate**: You can also run EKS pods on Fargate (Serverless), removing the need to manage EC2 instances entirely.

### 2. Storage & Persistence
-   **Stateless vs. Stateful**: Web servers (like WordPress frontend) are often stateless. Databases (MySQL) are stateful.
-   **EBS CSI Driver**: Kubernetes needs this driver to provision AWS EBS volumes dynamically.
    -   **Exam Tip**: If your pods are stuck in `Pending` state with "PersistentVolumeClaim is not bound", check if the **EBS CSI Driver** is installed and if the Node IAM Role has the `AmazonEBSCSIDriverPolicy`.
-   **Multi-AZ Storage**: EBS volumes are **Zonal**. A pod using an EBS volume cannot move to a different Availability Zone. For Multi-AZ storage, use **EFS**.

### 3. Networking
-   **VPC Design**: EKS requires subnets in at least two Availability Zones.
-   **Public vs. Private**:
    -   **Nodes** should generally be in **Private Subnets** for security.
    -   **Load Balancers** for public apps go in **Public Subnets**.
-   **Security Groups**: EKS automatically creates security groups to allow communication between the Control Plane and Nodes.

---

## Cleanup
To avoid ongoing charges, delete the resources when finished.

### Automated Cleanup (Recommended)
The easiest way to clean up is to use the provided script:

```bash
./cleanup.sh
```
This script will:
1.  Delete the Kubernetes namespace (removing LoadBalancers and EBS volumes).
2.  Delete the CloudFormation stack.
3.  Wait for completion.

You can verify everything is gone using:
```bash
./verify_cleanup.sh
```

### Manual Cleanup
If you prefer to do it manually:

1.  **Delete Kubernetes Resources**:
    ```bash
    kubectl delete -f wordpress-deployment.yaml
    ```
    *Wait for the LoadBalancer to be deleted.*

2.  **Delete CloudFormation Stack**:
    ```bash
    aws cloudformation delete-stack --stack-name eks-wordpress-lab
    ```
