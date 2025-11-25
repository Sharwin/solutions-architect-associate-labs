# Amazon EKS Hands-On Lab

## 🎯 Lab Scenario

**Real-World Use Case:** A company needs to deploy a containerized web application on Amazon EKS. The application must:
- Run in a highly available, multi-AZ setup
- Scale automatically based on demand
- Be accessible via a public load balancer
- Have proper IAM permissions and security
- Support logging and monitoring

## 📋 Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- kubectl installed
- Python 3.x (for testing script)
- AWS IAM permissions for EKS, EC2, VPC, IAM

## 🏗️ Architecture

This lab deploys:
1. **VPC** with public and private subnets across 2 AZs
2. **EKS Cluster** with control plane logging enabled
3. **Managed Node Group** with EC2 instances (t3.medium)
4. **OIDC Identity Provider** for IAM integration
5. **Sample Application** (Nginx) deployed via Kubernetes

## 🚀 Deployment Steps

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Review and Customize (Optional)

Edit `terraform.tfvars` if you want to change defaults:
- AWS region
- Cluster name
- Node instance types
- Scaling configuration

### 3. Plan Deployment

```bash
terraform plan
```

### 4. Deploy Infrastructure

```bash
terraform apply
```

**⏱️ Expected Time:** 15-20 minutes

### 5. Configure kubectl

After deployment completes, configure kubectl:

```bash
aws eks update-kubeconfig --region <your-region> --name eks-lab-cluster
```

Or use the output command:
```bash
terraform output -raw configure_kubectl | bash
```

### 6. Verify Cluster Access

```bash
kubectl cluster-info
kubectl get nodes
```

### 7. Deploy Sample Application

```bash
kubectl apply -f app-deployment.yaml
```

### 8. Run Automated Tests

Create virtual environment and install dependencies:
```bash
python3 -m venv venv
source venv/bin/activate
pip install requests
python test_cluster.py
```

### 9. Manual Testing

Check application status:
```bash
kubectl get pods -n demo-app
kubectl get svc -n demo-app
```

Get LoadBalancer URL:
```bash
kubectl get svc nginx-service -n demo-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Access the application:
```bash
curl http://<loadbalancer-url>
```

## 📚 AWS SAA-C03 Exam Tips

### EKS Fundamentals
- **EKS Control Plane**: Managed by AWS, runs in AWS account (not yours)
- **Node Groups**: Can be managed or self-managed
- **Networking**: Uses VPC CNI plugin (default) or other CNI plugins
- **Pricing**: $0.10/hour per cluster + EC2/node costs

### Key Limits
- **Clusters per region**: 100 (soft limit, can be increased)
- **Node groups per cluster**: 100
- **Nodes per node group**: Unlimited (but consider practical limits)
- **Pods per node**: Depends on instance type and CNI configuration

### Important Configurations
- **Cluster endpoint access**: Public, private, or both
- **Control plane logging**: Can enable API, audit, authenticator, controller manager, scheduler logs
- **Node group update strategy**: `maxUnavailable` or `maxSurge`
- **Instance types**: t3.medium minimum recommended for production

### Security Best Practices
- Use private subnets for nodes
- Enable control plane logging (especially audit logs)
- Use IAM roles for service accounts (IRSA) instead of storing credentials
- Enable encryption at rest for EBS volumes
- Use security groups to restrict traffic

### Networking
- **VPC CNI**: Assigns IP addresses from VPC subnet to pods
- **Service types**: ClusterIP, NodePort, LoadBalancer, ExternalName
- **LoadBalancer**: Creates Classic Load Balancer or Network Load Balancer
- **Subnet tags**: Required for ELB integration (`kubernetes.io/role/elb`)

### Scaling
- **Horizontal Pod Autoscaler (HPA)**: Scale pods based on metrics
- **Cluster Autoscaler**: Scale node groups based on pod scheduling needs
- **Node group scaling**: Configure min/max/desired size

### Monitoring & Logging
- **CloudWatch Logs**: Control plane logs go here
- **CloudWatch Container Insights**: For pod and node metrics
- **AWS X-Ray**: For distributed tracing
- **Prometheus**: Can be integrated for metrics

### Common Exam Scenarios
1. **Cost optimization**: Use Spot instances for non-critical workloads
2. **High availability**: Deploy across multiple AZs
3. **Security**: Private endpoint + VPN/Direct Connect
4. **Compliance**: Enable audit logging for compliance requirements
5. **Disaster recovery**: Use EKS in multiple regions

## 🧹 Cleanup

### Quick Cleanup

Use the automated cleanup script for complete cleanup:

```bash
./cleanup.sh
```

This script will:
1. Delete all Kubernetes applications (WordPress, Nginx)
2. Remove EBS CSI Driver
3. Delete IAM roles
4. Destroy Terraform infrastructure

### Manual Cleanup

**Important**: Always delete Kubernetes resources BEFORE destroying Terraform infrastructure.

```bash
# Step 1: Delete Kubernetes applications
kubectl delete namespace wordpress
kubectl delete -f app-deployment.yaml

# Step 2: Wait for LoadBalancers to delete (2-5 minutes)
kubectl get svc --all-namespaces | grep LoadBalancer

# Step 3: Destroy Terraform infrastructure
terraform destroy -auto-approve
```

### Verify Cleanup

```bash
./verify_cleanup.sh
```

**Note**: This will delete the EKS cluster, VPC, and all associated resources. EBS volumes and data will be permanently deleted!

## 📊 Expected Costs

- **EKS Cluster**: ~$0.10/hour (~$72/month)
- **EC2 Instances** (2x t3.medium): ~$0.0416/hour each (~$60/month total)
- **NAT Gateway**: ~$0.045/hour + data transfer (~$32/month)
- **Load Balancer**: ~$0.0225/hour + data transfer (~$16/month)
- **Total**: ~$180/month (estimate)

**💡 Tip**: Always clean up resources after labs to avoid charges!

## 🔍 Troubleshooting

### IAM Permission Issues (Service Control Policy)

**Error:** `AccessDeniedException: User: ... is not authorized to perform: eks:CreateCluster with an explicit deny in a service control policy`

**Solution:** This indicates an organizational SCP is blocking EKS creation. See `PERMISSIONS.md` for details.

**Workarounds:**
1. Contact your AWS administrator to modify the SCP
2. Use a different AWS account without SCP restrictions
3. Request temporary access for lab purposes

### kubectl connection issues
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Re-configure kubectl
aws eks update-kubeconfig --region <region> --name <cluster-name>
```

### Pods not starting
```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check node capacity
kubectl describe nodes
```

### LoadBalancer not getting external IP
- Check security group rules
- Verify subnet tags (`kubernetes.io/role/elb`)
- Check IAM permissions for ELB service

## 📖 Additional Resources

- [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

