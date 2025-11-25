# WordPress Deployment on EKS

## 🎉 Deployment Complete!

WordPress has been successfully deployed to your EKS cluster with MySQL database and persistent storage.

## 📋 Architecture

- **WordPress**: 2 replicas running Apache/PHP
- **MySQL 8.0**: Single instance with persistent storage
- **Persistent Volumes**: 10Gi EBS volumes for both MySQL and WordPress
- **LoadBalancer**: Classic Load Balancer exposing WordPress on port 80

## 🌐 Access WordPress

### Get the LoadBalancer URL:
```bash
kubectl get svc wordpress -n wordpress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### Access in Browser:
Open: `http://a686ba4a269f84ce3bf3f337e7fc6538-1998407850.us-east-1.elb.amazonaws.com`

You'll be redirected to the WordPress setup page where you can:
1. Choose your language
2. Set up your site title, admin username, and password
3. Complete the WordPress installation

## 🔐 Database Credentials

The WordPress application is pre-configured to connect to MySQL:

- **Database Host**: `mysql` (Kubernetes service name)
- **Database Name**: `wordpress`
- **Database User**: `wordpress`
- **Database Password**: `WordPress123!`

*Note: These credentials are stored in Kubernetes Secrets. In production, use stronger passwords and consider using AWS Secrets Manager.*

## 📊 Check Status

```bash
# View all WordPress resources
kubectl get all -n wordpress

# Check pod status
kubectl get pods -n wordpress

# View persistent volumes
kubectl get pvc -n wordpress

# View services
kubectl get svc -n wordpress

# View WordPress logs
kubectl logs -n wordpress deployment/wordpress --tail=50

# View MySQL logs
kubectl logs -n wordpress deployment/mysql --tail=50
```

## 🔧 Useful Commands

### Scale WordPress
```bash
kubectl scale deployment wordpress -n wordpress --replicas=3
```

### Access MySQL directly
```bash
# Get MySQL pod name
MYSQL_POD=$(kubectl get pods -n wordpress -l app=mysql -o jsonpath='{.items[0].metadata.name}')

# Connect to MySQL
kubectl exec -it $MYSQL_POD -n wordpress -- mysql -u wordpress -pWordPress123! wordpress
```

### Backup WordPress Data
```bash
# Backup MySQL database
kubectl exec -it $(kubectl get pods -n wordpress -l app=mysql -o jsonpath='{.items[0].metadata.name}') -n wordpress -- mysqldump -u wordpress -pWordPress123! wordpress > wordpress-backup.sql
```

## 🗄️ Persistent Storage

Both MySQL and WordPress use EBS volumes (gp2) for persistent storage:

- **MySQL PVC**: `mysql-pvc` (10Gi)
- **WordPress PVC**: `wordpress-pvc` (10Gi)

Data persists even if pods are deleted and recreated.

## 🎓 AWS SAA-C03 Exam Tips

### EBS CSI Driver
- **EBS CSI Driver**: Required for dynamic EBS volume provisioning in EKS
- **Installation**: Can be installed via addon (if supported) or via Kubernetes manifests
- **IAM Role**: Service account needs IAM role annotation for IRSA (IAM Roles for Service Accounts)
- **Storage Classes**: `gp2` is the default EBS storage class in EKS

### Persistent Volumes
- **Access Modes**: 
  - `ReadWriteOnce` (RWO): Single node read/write
  - `ReadOnlyMany` (ROX): Multiple nodes read-only
  - `ReadWriteMany` (RWX): Multiple nodes read/write
- **Volume Binding**: `WaitForFirstConsumer` delays binding until pod is scheduled
- **Reclaim Policy**: `Delete` (default) removes volume when PVC is deleted

### Stateful Applications
- **MySQL**: Stateful application requiring persistent storage
- **Headless Service**: `clusterIP: None` for StatefulSet-like behavior
- **Database High Availability**: Consider MySQL replication or RDS for production

### LoadBalancer Service
- **Classic Load Balancer**: Created automatically for LoadBalancer type services
- **External Access**: Provides public IP/DNS for external access
- **Cost**: ~$0.0225/hour + data transfer

## 🧹 Cleanup

To remove WordPress deployment:

```bash
# Delete WordPress namespace (includes all resources)
kubectl delete namespace wordpress

# Or delete individual resources
kubectl delete -f wordpress-deployment.yaml
```

**Note**: Deleting PVCs will delete the EBS volumes and all data!

## 📝 Files Created

- `wordpress-deployment.yaml`: Complete WordPress + MySQL deployment
- `ebs-csi-iam-policy.json`: IAM policy for EBS CSI driver
- `ebs-csi-trust-policy.json`: Trust policy for EBS CSI driver IAM role

## 🔍 Troubleshooting

### Pods stuck in Pending
```bash
kubectl describe pod <pod-name> -n wordpress
kubectl get events -n wordpress --sort-by='.lastTimestamp'
```

### PVC not binding
```bash
kubectl describe pvc <pvc-name> -n wordpress
kubectl get pods -n kube-system | grep ebs-csi
```

### WordPress can't connect to MySQL
```bash
# Check MySQL pod is running
kubectl get pods -n wordpress -l app=mysql

# Test MySQL connection from WordPress pod
kubectl exec -it <wordpress-pod> -n wordpress -- curl mysql:3306
```

## ✨ Next Steps

1. Complete WordPress setup via web interface
2. Install WordPress themes and plugins
3. Configure WordPress settings
4. Consider adding:
   - Ingress controller (ALB Ingress Controller or NGINX)
   - SSL/TLS certificates (AWS Certificate Manager)
   - CloudFront CDN for static content
   - RDS for MySQL instead of self-managed MySQL

