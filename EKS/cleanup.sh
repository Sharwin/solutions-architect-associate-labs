#!/bin/bash
# EKS Lab Cleanup Script
# This script ensures proper cleanup order to avoid resource dependencies

set -e

echo "=========================================="
echo "EKS Lab Cleanup Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if kubectl is configured
check_kubectl() {
    if ! kubectl cluster-info &>/dev/null; then
        echo -e "${YELLOW}Warning: kubectl is not configured or cluster is not accessible${NC}"
        return 1
    fi
    return 0
}

# Step 1: Delete Kubernetes Applications
echo -e "${GREEN}Step 1: Deleting Kubernetes applications...${NC}"
if check_kubectl; then
    # Delete WordPress namespace (includes all resources)
    if kubectl get namespace wordpress &>/dev/null; then
        echo "  - Deleting WordPress namespace..."
        kubectl delete namespace wordpress --wait=true --timeout=120s || true
        echo "  ✓ WordPress namespace deleted"
    else
        echo "  - WordPress namespace not found (already deleted)"
    fi
    
    # Delete demo-app namespace
    if kubectl get namespace demo-app &>/dev/null; then
        echo "  - Deleting demo-app namespace..."
        kubectl delete namespace demo-app --wait=true --timeout=120s || true
        echo "  ✓ demo-app namespace deleted"
    else
        echo "  - demo-app namespace not found (already deleted)"
    fi
    
    # Wait for LoadBalancers to be deleted (they take time)
    echo "  - Waiting for LoadBalancers to be deleted..."
    sleep 30
else
    echo -e "${YELLOW}  Skipping Kubernetes cleanup (kubectl not configured)${NC}"
fi

# Step 2: Delete EBS CSI Driver (optional, but good practice)
echo ""
echo -e "${GREEN}Step 2: Cleaning up EBS CSI Driver...${NC}"
if check_kubectl; then
    if kubectl get deployment ebs-csi-controller -n kube-system &>/dev/null; then
        echo "  - Deleting EBS CSI Driver..."
        kubectl delete -k "https://github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.28" --ignore-not-found=true || true
        echo "  ✓ EBS CSI Driver deleted"
    else
        echo "  - EBS CSI Driver not found (already deleted)"
    fi
else
    echo -e "${YELLOW}  Skipping EBS CSI Driver cleanup${NC}"
fi

# Step 3: Delete EBS CSI IAM Role (if created)
echo ""
echo -e "${GREEN}Step 3: Cleaning up EBS CSI IAM Role...${NC}"
if aws iam get-role --role-name AmazonEKS_EBS_CSI_DriverRole &>/dev/null; then
    echo "  - Deleting IAM role policies..."
    aws iam delete-role-policy --role-name AmazonEKS_EBS_CSI_DriverRole --policy-name EBS-CSI-Driver-Policy 2>/dev/null || true
    
    echo "  - Deleting IAM role..."
    aws iam delete-role --role-name AmazonEKS_EBS_CSI_DriverRole 2>/dev/null || true
    echo "  ✓ EBS CSI IAM Role deleted"
else
    echo "  - EBS CSI IAM Role not found (already deleted)"
fi

# Step 4: Destroy Terraform Infrastructure
echo ""
echo -e "${GREEN}Step 4: Destroying Terraform infrastructure...${NC}"
if [ -f "terraform.tfstate" ] || [ -f ".terraform/terraform.tfstate" ]; then
    echo "  - Running terraform destroy..."
    terraform destroy -auto-approve
    echo "  ✓ Terraform infrastructure destroyed"
else
    echo -e "${YELLOW}  No Terraform state found (already destroyed)${NC}"
fi

# Step 5: Verify cleanup
echo ""
echo -e "${GREEN}Step 5: Verifying cleanup...${NC}"
if check_kubectl; then
    echo "  - Checking for remaining LoadBalancers..."
    REMAINING_LB=$(kubectl get svc --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.spec.type=="LoadBalancer") | "\(.metadata.namespace)/\(.metadata.name)"' 2>/dev/null | wc -l || echo "0")
    if [ "$REMAINING_LB" -gt 0 ]; then
        echo -e "${YELLOW}  Warning: $REMAINING_LB LoadBalancer(s) still exist${NC}"
        echo "  They will be automatically deleted when the cluster is destroyed"
    else
        echo "  ✓ No LoadBalancers found"
    fi
else
    echo "  - Cannot verify (kubectl not configured)"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "Cleanup Complete!"
echo "==========================================${NC}"
echo ""
echo "Note: It may take a few minutes for AWS to fully delete all resources."
echo "Check AWS Console to verify all resources are deleted."

