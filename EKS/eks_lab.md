# Amazon EKS Hands-On Lab Guide

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Lab Architecture](#lab-architecture)
4. [Step 1: Infrastructure Deployment](#step-1-infrastructure-deployment)
5. [Step 2: Configure kubectl](#step-2-configure-kubectl)
6. [Step 3: Verify Cluster](#step-3-verify-cluster)
7. [Step 4: Deploy Sample Application](#step-4-deploy-sample-application)
8. [Step 5: Deploy WordPress](#step-5-deploy-wordpress)
9. [Step 6: Testing and Validation](#step-6-testing-and-validation)
10. [Cleanup](#cleanup)
11. [Exam Tips](#exam-tips)

---

## Overview

This lab demonstrates deploying a production-ready Amazon EKS cluster with:
- Managed node groups
- Persistent storage (EBS CSI driver)
- Sample applications (Nginx and WordPress)
- LoadBalancer services
- Multi-AZ high availability

**Estimated Time**: 30-45 minutes  
**Cost**: ~$0.20/hour (~$180/month if left running)

---

## Prerequisites

### Required Tools
- AWS CLI configured with credentials
- Terraform >= 1.0
- kubectl installed
- Python 3.x (for testing script)

### Verify Prerequisites

```bash
# Check AWS CLI
aws --version
# Output: aws-cli/2.x.x Python/3.x.x ...

# Check AWS credentials
aws sts get-caller-identity
# Output:
# {
#     "UserId": "AIDAUBFX4OAZFXJERHLSS",
#     "Account": "277411033138",
#     "Arn": "arn:aws:iam::277411033138:user/ivan.bello"
# }

# Check Terraform
terraform version
# Output: Terraform v1.x.x

# Check kubectl
kubectl version --client
# Output: Client Version: version.Info{Major:"1", Minor:"28", ...}
```

### Required IAM Permissions

Your AWS user/role needs permissions for:
- EKS (CreateCluster, DescribeCluster, etc.)
- EC2 (VPC, subnets, security groups, instances)
- IAM (CreateRole, AttachRolePolicy, etc.)
- EBS (for persistent volumes)

---

## Lab Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    EKS Cluster                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │         Control Plane (Managed by AWS)          │   │
│  │  - API Server                                    │   │
│  │  - etcd                                         │   │
│  │  - Scheduler                                    │   │
│  └──────────────────────────────────────────────────┘   │
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │              Node Group (2 nodes)              │   │
│  │  ┌──────────────┐      ┌──────────────┐         │   │
│  │  │ Node 1       │      │ Node 2       │         │   │
│  │  │ (t3.medium)   │      │ (t3.medium)   │         │   │
│  │  │              │      │              │         │   │
│  │  │ Pods:        │      │ Pods:        │         │   │
│  │  │ - Nginx      │      │ - Nginx      │         │   │
│  │  │ - WordPress   │      │ - WordPress   │         │   │
│  │  └──────────────┘      └──────────────┘         │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
         │                    │
         ▼                    ▼
┌────────────────┐   ┌────────────────┐
│ LoadBalancer   │   │ LoadBalancer   │
│ (Nginx)        │   │ (WordPress)    │
└────────────────┘   └────────────────┘
```

**VPC Configuration**:
- VPC CIDR: 10.0.0.0/16
- 2 Public subnets (us-east-1a, us-east-1b)
- 2 Private subnets (us-east-1a, us-east-1b)
- NAT Gateway for private subnet internet access
- Internet Gateway for public subnets

---

## Step 1: Infrastructure Deployment

### 1.1 Initialize Terraform

```bash
cd /Users/ivan.bello/Documents/cloudcamp/labs/EKS
terraform init
```

**Expected Output**:
```
Initializing the backend...
Initializing modules...
Downloading registry.terraform.io/terraform-aws-modules/vpc/aws 5.21.0 for vpc...
- vpc in .terraform/modules/vpc
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.100.0...
- Installed hashicorp/aws v5.100.0
- Installing hashicorp/tls v4.1.0...
- Installed hashicorp/tls v4.1.0

Terraform has been successfully initialized!
```

### 1.2 Review Deployment Plan

```bash
terraform plan
```

**Expected Output** (summary):
```
Plan: 28 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + cluster_name              = "eks-lab-cluster"
  + cluster_version           = "1.28"
  + configure_kubectl         = "aws eks update-kubeconfig --region us-east-1 --name eks-lab-cluster"
  + vpc_id                    = (known after apply)
```

### 1.3 Deploy Infrastructure

```bash
terraform apply -auto-approve
```

**Expected Output** (key milestones):
```
aws_iam_role.eks_cluster_role: Creating...
aws_iam_role.eks_cluster_role: Creation complete after 1s
module.vpc.aws_vpc.this[0]: Creating...
module.vpc.aws_vpc.this[0]: Creation complete after 13s
aws_eks_cluster.main: Creating...
aws_eks_cluster.main: Still creating... [10m00s elapsed]
aws_eks_cluster.main: Creation complete after 10m41s
aws_eks_node_group.main: Creating...
aws_eks_node_group.main: Creation complete after 2m18s

Apply complete! Resources: 28 added, 0 changed, 0 destroyed.

Outputs:
cluster_arn = "arn:aws:eks:us-east-1:277411033138:cluster/eks-lab-cluster"
cluster_endpoint = "https://C45E1245D8D297EBD3FDB1308AB748EB.gr7.us-east-1.eks.amazonaws.com"
cluster_name = "eks-lab-cluster"
cluster_version = "1.28"
configure_kubectl = "aws eks update-kubeconfig --region us-east-1 --name eks-lab-cluster"
```

**⏱️ Expected Time**: 15-20 minutes

**Key Resources Created**:
- VPC with public/private subnets
- EKS cluster (control plane)
- Managed node group (2 EC2 instances)
- IAM roles and policies
- OIDC identity provider

---

## Step 2: Configure kubectl

### 2.1 Update kubeconfig

```bash
aws eks update-kubeconfig --region us-east-1 --name eks-lab-cluster
```

**Expected Output**:
```
Added new context arn:aws:eks:us-east-1:277411033138:cluster/eks-lab-cluster to /Users/ivan.bello/.kube/config
```

### 2.2 Verify kubectl Connection

```bash
kubectl cluster-info
```

**Expected Output**:
```
Kubernetes control plane is running at https://C45E1245D8D297EBD3FDB1308AB748EB.gr7.us-east-1.eks.amazonaws.com
CoreDNS is running at https://C45E1245D8D297EBD3FDB1308AB748EB.gr7.us-east-1.eks.amazonaws.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

---

## Step 3: Verify Cluster

### 3.1 Check Node Status

```bash
kubectl get nodes
```

**Expected Output**:
```
NAME                         STATUS   ROLES    AGE   VERSION
ip-10-0-0-132.ec2.internal   Ready    <none>   2m    v1.28.15-eks-c39b1d0
ip-10-0-1-170.ec2.internal   Ready    <none>   2m    v1.28.15-eks-c39b1d0
```

### 3.2 Get Detailed Node Information

```bash
kubectl get nodes -o wide
```

**Expected Output**:
```
NAME                         STATUS   ROLES    AGE   VERSION                INTERNAL-IP   EXTERNAL-IP   OS-IMAGE         KERNEL-VERSION                  CONTAINER-RUNTIME
ip-10-0-0-132.ec2.internal   Ready    <none>   2m    v1.28.15-eks-c39b1d0   10.0.0.132    <none>        Amazon Linux 2   5.10.245-241.978.amzn2.x86_64   containerd://1.7.27
ip-10-0-1-170.ec2.internal   Ready    <none>   2m    v1.28.15-eks-c39b1d0   10.0.1.170    <none>        Amazon Linux 2   5.10.245-241.978.amzn2.x86_64   containerd://1.7.27
```

### 3.3 Check System Pods

```bash
kubectl get pods -n kube-system
```

**Expected Output** (sample):
```
NAME                       READY   STATUS    RESTARTS   AGE
aws-node-xxxxx             1/1     Running   0          3m
coredns-xxxxx              1/1     Running   0          5m
coredns-xxxxx              1/1     Running   0          5m
kube-proxy-xxxxx           1/1     Running   0          3m
```

---

## Step 4: Deploy Sample Application

### 4.1 Deploy Nginx Application

```bash
kubectl apply -f app-deployment.yaml
```

**Expected Output**:
```
namespace/demo-app created
deployment.apps/nginx-deployment created
service/nginx-service created
```

### 4.2 Check Pod Status

```bash
kubectl get pods -n demo-app
```

**Expected Output**:
```
NAME                               READY   STATUS    RESTARTS   AGE
nginx-deployment-b696bd559-kkx5f   1/1     Running   0          10s
nginx-deployment-b696bd559-pthf6   1/1     Running   0          10s
nginx-deployment-b696bd559-rxbps   1/1     Running   0          10s
```

### 4.3 Check Service Status

```bash
kubectl get svc -n demo-app
```

**Expected Output**:
```
NAME            TYPE           CLUSTER-IP       EXTERNAL-IP                                                              PORT(S)        AGE
nginx-service   LoadBalancer   172.20.251.230   ab8d36a74d0554f778f8a78901377353-922349670.us-east-1.elb.amazonaws.com   80:31873/TCP   15s
```

**Note**: LoadBalancer external IP may take 1-2 minutes to provision.

### 4.4 Test Application

```bash
# Get LoadBalancer URL
LOADBALANCER_URL=$(kubectl get svc nginx-service -n demo-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test HTTP endpoint
curl -I http://$LOADBALANCER_URL
```

**Expected Output**:
```
HTTP/1.1 200 OK
Server: nginx/1.25.5
Date: Fri, 21 Nov 2025 15:25:17 GMT
Content-Type: text/html
Content-Length: 615
```

### 4.5 View Pod Logs

```bash
kubectl logs -n demo-app deployment/nginx-deployment --tail=10
```

**Expected Output**:
```
10.0.1.170 - - [21/Nov/2025:15:25:17 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/8.7.1" "-"
```

---

## Step 5: Deploy WordPress

### 5.1 Install EBS CSI Driver (Required for Persistent Volumes)

```bash
# Create IAM role for EBS CSI driver
aws iam create-role \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --assume-role-policy-document file://ebs-csi-trust-policy.json

# Attach IAM policy
aws iam put-role-policy \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --policy-name EBS-CSI-Driver-Policy \
  --policy-document file://ebs-csi-iam-policy.json

# Install EBS CSI driver
kubectl apply -k "https://github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.28"

# Annotate service account with IAM role
ROLE_ARN=$(aws iam get-role --role-name AmazonEKS_EBS_CSI_DriverRole --query 'Role.Arn' --output text)
kubectl annotate serviceaccount ebs-csi-controller-sa -n kube-system eks.amazonaws.com/role-arn=$ROLE_ARN --overwrite

# Restart EBS CSI controller pods
kubectl delete pods -n kube-system -l app=ebs-csi-controller
```

**Expected Output**:
```
Role created
EBS CSI driver installed
Service account annotated
Pods deleted and restarted
```

### 5.2 Verify EBS CSI Driver

```bash
kubectl get pods -n kube-system | grep ebs
```

**Expected Output**:
```
ebs-csi-controller-695b645df6-g8jkt   6/6     Running   0          30s
ebs-csi-controller-695b645df6-l7bhg   6/6     Running   0          30s
ebs-csi-node-2tsls                    3/3     Running   0          2m
ebs-csi-node-8r4wb                    3/3     Running   0          2m
```

### 5.3 Deploy WordPress

```bash
kubectl apply -f wordpress-deployment.yaml
```

**Expected Output**:
```
namespace/wordpress created
persistentvolumeclaim/mysql-pvc created
persistentvolumeclaim/wordpress-pvc created
secret/mysql-secret created
deployment.apps/mysql created
service/mysql created
deployment.apps/wordpress created
service/wordpress created
```

### 5.4 Monitor WordPress Deployment

```bash
# Watch pods being created
kubectl get pods -n wordpress -w
```

**Expected Output** (initial):
```
NAME                        READY   STATUS    RESTARTS   AGE
mysql-686c798fd8-9dlgt      0/1     Pending   0          5s
wordpress-7c4b65c49-4q2gg   0/1     Pending   0          5s
wordpress-7c4b65c49-6hzfm   0/1     Pending   0          5s
```

**Expected Output** (after PVCs bind):
```
NAME                        READY   STATUS    RESTARTS   AGE
mysql-686c798fd8-9dlgt      1/1     Running   0          2m
wordpress-7c4b65c49-4q2gg   1/1     Running   0          2m
wordpress-7c4b65c49-6hzfm   1/1     Running   0          2m
```

### 5.5 Check Persistent Volumes

```bash
kubectl get pvc -n wordpress
```

**Expected Output**:
```
NAME            STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
mysql-pvc       Bound    pvc-9a1a9ef4-f8b2-43bc-adf1-917561e1584d   10Gi       RWO            gp2            2m
wordpress-pvc   Bound    pvc-738ff694-a28d-48db-9102-169eb09b3681   10Gi       RWO            gp2            2m
```

### 5.6 Get WordPress LoadBalancer URL

```bash
kubectl get svc wordpress -n wordpress
```

**Expected Output**:
```
NAME        TYPE           CLUSTER-IP      EXTERNAL-IP                                                               PORT(S)        AGE
wordpress   LoadBalancer   172.20.45.128   a686ba4a269f84ce3bf3f337e7fc6538-1998407850.us-east-1.elb.amazonaws.com   80:31610/TCP   3m
```

### 5.7 Access WordPress

```bash
WORDPRESS_URL=$(kubectl get svc wordpress -n wordpress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "WordPress URL: http://$WORDPRESS_URL"

# Test endpoint
curl -I http://$WORDPRESS_URL
```

**Expected Output**:
```
WordPress URL: http://a686ba4a269f84ce3bf3f337e7fc6538-1998407850.us-east-1.elb.amazonaws.com
HTTP/1.1 302 Found
Date: Fri, 21 Nov 2025 15:34:19 GMT
Server: Apache/2.4.57 (Debian)
X-Powered-By: PHP/8.2.17
```

**Note**: HTTP 302 is expected - WordPress redirects to setup page.

Open the URL in your browser to complete WordPress installation.

---

## Step 6: Testing and Validation

### 6.1 Run Automated Test Script

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install requests

# Run tests
python test_cluster.py
```

**Expected Output** (summary):
```
============================================================
EKS CLUSTER TESTING SUITE
============================================================

TEST 1: Testing kubectl connection to EKS cluster
✓ kubectl is connected to the cluster

TEST 2: Checking cluster nodes
Total nodes: 2
  - ip-10-0-0-132.ec2.internal: Ready
  - ip-10-0-1-170.ec2.internal: Ready

TEST 3: Checking namespaces
✓ Namespaces verified

TEST 4: Checking application deployments
✓ All 3 pods are running!

TEST 5: Checking LoadBalancer service
✓ LoadBalancer endpoint ready
```

### 6.2 Verify Pod Distribution

```bash
kubectl get pods -n wordpress -o wide
```

**Expected Output**:
```
NAME                        READY   STATUS    RESTARTS   AGE     IP           NODE                         
mysql-686c798fd8-9dlgt      1/1     Running   0          5m      10.0.1.70    ip-10-0-1-170.ec2.internal   
wordpress-7c4b65c49-4q2gg   1/1     Running   0          5m      10.0.0.213   ip-10-0-0-132.ec2.internal   
wordpress-7c4b65c49-6hzfm   1/1     Running   0          5m      10.0.0.103   ip-10-0-0-132.ec2.internal   
```

**Note**: Pods are distributed across nodes for high availability.

### 6.3 Test Scaling

```bash
# Scale WordPress deployment
kubectl scale deployment wordpress -n wordpress --replicas=3

# Verify scaling
kubectl get pods -n wordpress
```

**Expected Output**:
```
NAME                        READY   STATUS    RESTARTS   AGE
mysql-686c798fd8-9dlgt      1/1     Running   0          6m
wordpress-7c4b65c49-4q2gg   1/1     Running   0          6m
wordpress-7c4b65c49-6hzfm   1/1     Running   0          6m
wordpress-7c4b65c49-xxxxx   1/1     Running   0          10s
```

### 6.4 View Application Logs

```bash
# WordPress logs
kubectl logs -n wordpress deployment/wordpress --tail=20

# MySQL logs
kubectl logs -n wordpress deployment/mysql --tail=20
```

---

## Cleanup

### Quick Cleanup (Automated Script)

The easiest way to clean up everything is to use the provided cleanup script:

```bash
./cleanup.sh
```

**Expected Output**:
```
==========================================
EKS Lab Cleanup Script
==========================================

Step 1: Deleting Kubernetes applications...
  - Deleting WordPress namespace...
  ✓ WordPress namespace deleted
  - Deleting demo-app namespace...
  ✓ demo-app namespace deleted
  - Waiting for LoadBalancers to be deleted...

Step 2: Cleaning up EBS CSI Driver...
  ✓ EBS CSI Driver deleted

Step 3: Cleaning up EBS CSI IAM Role...
  ✓ EBS CSI IAM Role deleted

Step 4: Destroying Terraform infrastructure...
  - Running terraform destroy...
  ✓ Terraform infrastructure destroyed

Step 5: Verifying cleanup...
  ✓ No LoadBalancers found

==========================================
Cleanup Complete!
==========================================
```

### Manual Cleanup (Step-by-Step)

If you prefer to clean up manually, follow these steps in order:

#### Step 1: Delete Kubernetes Applications

**Important**: Delete Kubernetes resources BEFORE destroying Terraform infrastructure to avoid dependency issues.

```bash
# Delete WordPress namespace (includes all WordPress resources)
kubectl delete namespace wordpress

# Delete Nginx application
kubectl delete -f app-deployment.yaml
```

**Expected Output**:
```
namespace "wordpress" deleted
namespace "demo-app" deleted
deployment.apps "nginx-deployment" deleted
service "nginx-service" deleted
```

**Wait for LoadBalancers**: LoadBalancers can take 2-5 minutes to delete. Wait before proceeding:

```bash
# Check if LoadBalancers are deleted
kubectl get svc --all-namespaces | grep LoadBalancer

# Wait until no LoadBalancers are shown, then proceed
```

#### Step 2: Delete EBS CSI Driver (Optional)

```bash
# Delete EBS CSI Driver
kubectl delete -k "https://github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.28" --ignore-not-found=true
```

#### Step 3: Delete EBS CSI IAM Role (Optional)

```bash
# Delete IAM role policy
aws iam delete-role-policy \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --policy-name EBS-CSI-Driver-Policy

# Delete IAM role
aws iam delete-role --role-name AmazonEKS_EBS_CSI_DriverRole
```

#### Step 4: Destroy Terraform Infrastructure

```bash
terraform destroy -auto-approve
```

**Expected Output** (summary):
```
Plan: 0 to add, 0 to change, 28 to destroy.

aws_eks_node_group.main: Destroying...
aws_eks_node_group.main: Still destroying... [2m00s elapsed]
aws_eks_node_group.main: Destruction complete after 2m18s

aws_eks_cluster.main: Destroying...
aws_eks_cluster.main: Still destroying... [5m00s elapsed]
aws_eks_cluster.main: Destruction complete after 5m30s

module.vpc.aws_nat_gateway.this[0]: Destroying...
module.vpc.aws_nat_gateway.this[0]: Destruction complete after 1m1s

module.vpc.aws_vpc.this[0]: Destroying...
module.vpc.aws_vpc.this[0]: Destruction complete after 1s

Destroy complete! Resources: 28 destroyed.
```

**⏱️ Expected Time**: 10-15 minutes

**Important**: This will delete all resources including:
- EKS cluster
- EC2 instances (node group)
- VPC and networking (subnets, NAT Gateway, Internet Gateway)
- Load balancers (created by LoadBalancer services)
- EBS volumes (data will be lost!)
- IAM roles and policies

### Verify Cleanup

You can use the verification script to check if cleanup is complete:

```bash
./verify_cleanup.sh
```

**Expected Output**:
```
==========================================
EKS Lab Cleanup Verification
==========================================

Checking EKS clusters...
  ✓ No EKS clusters found

Checking LoadBalancers...
  ✓ No LoadBalancers found

Checking kubectl access...
  ✓ kubectl not configured (cluster likely deleted)

Checking IAM roles...
  ✓ EBS CSI Driver IAM role deleted
  ✓ EKS cluster IAM role deleted

Checking Terraform state...
  ✓ No Terraform state file found

==========================================
✓ Cleanup verification passed!
==========================================
```

**Manual Verification**:

```bash
# Verify no EKS clusters exist
aws eks list-clusters --region us-east-1

# Verify no LoadBalancers exist (may take a few minutes)
aws elb describe-load-balancers --region us-east-1 --query 'LoadBalancerDescriptions[?contains(LoadBalancerName, `eks`)].LoadBalancerName' --output text

# Verify Terraform state is clean
terraform state list
```

**Expected Output**:
```
{
    "clusters": []
}
(empty output - no LoadBalancers)
No state file found or state is empty
```

### Troubleshooting Cleanup

#### LoadBalancer Won't Delete

If LoadBalancers are stuck, they will be automatically deleted when the EKS cluster is destroyed. You can also manually delete them:

```bash
# List LoadBalancers
aws elb describe-load-balancers --region us-east-1 --query 'LoadBalancerDescriptions[?contains(LoadBalancerName, `eks`)].LoadBalancerName' --output text

# Delete LoadBalancer (replace with actual name)
aws elb delete-load-balancer --load-balancer-name <name> --region us-east-1
```

#### PVC Won't Delete

Persistent Volume Claims are automatically deleted when namespaces are deleted. If stuck:

```bash
# Force delete PVC (data will be lost)
kubectl delete pvc <pvc-name> -n <namespace> --force --grace-period=0
```

#### Terraform Destroy Fails

If Terraform destroy fails due to dependencies:

1. **Check for stuck resources**:
   ```bash
   terraform state list
   ```

2. **Manually delete problematic resources** (if needed):
   ```bash
   # Remove from state (use with caution)
   terraform state rm <resource-address>
   ```

3. **Retry destroy**:
   ```bash
   terraform destroy -auto-approve
   ```

#### EKS Cluster Won't Delete

If the EKS cluster is stuck deleting:

1. Check for remaining node groups:
   ```bash
   aws eks list-nodegroups --cluster-name eks-lab-cluster --region us-east-1
   ```

2. Manually delete node groups if needed:
   ```bash
   aws eks delete-nodegroup --cluster-name eks-lab-cluster --nodegroup-name eks-lab-cluster-node-group --region us-east-1
   ```

3. Then delete cluster:
   ```bash
   aws eks delete-cluster --name eks-lab-cluster --region us-east-1
   ```

---

## Exam Tips

### EKS Fundamentals

1. **Control Plane**: Managed by AWS, runs in AWS account (not yours)
   - Cost: $0.10/hour per cluster
   - High availability across multiple AZs
   - API endpoint can be public, private, or both

2. **Node Groups**: Can be managed or self-managed
   - Managed node groups: AWS handles updates, scaling
   - Self-managed: Full control, more responsibility
   - Instance types: Minimum t3.medium recommended

3. **Networking**:
   - VPC CNI plugin assigns VPC IPs to pods
   - Subnet tags required for ELB:
     - `kubernetes.io/role/elb = "1"` (public subnets)
     - `kubernetes.io/role/internal-elb = "1"` (private subnets)
   - Cluster tag: `kubernetes.io/cluster/<name> = "shared"`

### IAM Roles

1. **Cluster Role**: Required for EKS control plane
   - Policy: `AmazonEKSClusterPolicy`
   - Service: `eks.amazonaws.com`

2. **Node Group Role**: Required for worker nodes
   - Policies:
     - `AmazonEKSWorkerNodePolicy`
     - `AmazonEKS_CNI_Policy`
     - `AmazonEC2ContainerRegistryReadOnly`
   - Service: `ec2.amazonaws.com`

3. **IRSA (IAM Roles for Service Accounts)**:
   - Uses OIDC identity provider
   - Allows pods to assume IAM roles
   - More secure than storing credentials

### Persistent Storage

1. **EBS CSI Driver**: Required for dynamic EBS provisioning
   - Install via addon (if supported) or Kubernetes manifests
   - Requires IAM role with EBS permissions
   - StorageClass `gp2` is default

2. **Persistent Volumes**:
   - Access modes: RWO (single node), ROX (read-only many), RWX (read-write many)
   - Volume binding: `WaitForFirstConsumer` delays binding until pod scheduled
   - Reclaim policy: `Delete` (default) or `Retain`

### Service Types

1. **ClusterIP**: Internal service (default)
2. **NodePort**: Exposes on node IPs
3. **LoadBalancer**: Creates Classic or Network Load Balancer
4. **ExternalName**: Maps to external DNS name

### High Availability

1. **Multi-AZ Deployment**: Deploy across availability zones
2. **Pod Distribution**: Use `podAntiAffinity` to spread pods
3. **Node Group Scaling**: Configure min/max/desired size
4. **Horizontal Pod Autoscaler**: Scale pods based on metrics

### Monitoring and Logging

1. **Control Plane Logging**: Enable in cluster config
   - Types: api, audit, authenticator, controllerManager, scheduler
   - Logs go to CloudWatch Logs
   - Important for compliance

2. **Container Insights**: CloudWatch Container Insights for metrics
3. **Prometheus**: Can be integrated for advanced monitoring

### Cost Optimization

1. **Right-size instances**: Use appropriate instance types
2. **Spot instances**: For non-critical workloads
3. **Cluster autoscaler**: Scale nodes based on demand
4. **Clean up**: Always destroy resources after labs

### Common Exam Scenarios

1. **Private endpoint**: Use VPN or Direct Connect
2. **Cost optimization**: Spot instances, right-sizing
3. **Security**: Private subnets, IRSA, encryption
4. **Compliance**: Enable audit logging
5. **Disaster recovery**: Multi-region deployment

---

## Troubleshooting

### Pods Stuck in Pending

```bash
# Describe pod for details
kubectl describe pod <pod-name> -n <namespace>

# Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

### PVC Not Binding

```bash
# Check PVC status
kubectl describe pvc <pvc-name> -n <namespace>

# Verify EBS CSI driver
kubectl get pods -n kube-system | grep ebs-csi
```

### LoadBalancer Not Getting External IP

```bash
# Check service
kubectl describe svc <service-name> -n <namespace>

# Verify subnet tags
aws ec2 describe-subnets --filters "Name=tag:kubernetes.io/role/elb,Values=1"
```

### Cannot Connect to Cluster

```bash
# Re-configure kubectl
aws eks update-kubeconfig --region <region> --name <cluster-name>

# Verify AWS credentials
aws sts get-caller-identity
```

---

## Summary

This lab demonstrated:

✅ **EKS Cluster Deployment**: Complete infrastructure with Terraform  
✅ **Node Group Configuration**: Managed node group with auto-scaling  
✅ **Application Deployment**: Nginx and WordPress applications  
✅ **Persistent Storage**: EBS volumes with EBS CSI driver  
✅ **Load Balancing**: Classic Load Balancer for external access  
✅ **High Availability**: Multi-AZ deployment with pod distribution  

**Key Takeaways**:
- EKS control plane is managed by AWS
- Node groups require specific IAM roles and policies
- Subnet tagging is critical for ELB integration
- EBS CSI driver enables persistent storage
- LoadBalancer service type creates AWS load balancers automatically

**Next Steps**:
- Explore Ingress controllers (ALB Ingress Controller)
- Implement Horizontal Pod Autoscaler
- Set up monitoring with CloudWatch Container Insights
- Configure SSL/TLS with AWS Certificate Manager
- Consider RDS for managed database services

---

## Additional Resources

- [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [EBS CSI Driver](https://github.com/kubernetes-sigs/aws-ebs-csi-driver)

---

**Lab Created**: November 2025  
**AWS Region**: us-east-1  
**Kubernetes Version**: 1.28

