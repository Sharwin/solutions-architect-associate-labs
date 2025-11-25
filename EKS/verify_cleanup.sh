#!/bin/bash
# Script to verify cleanup is complete

echo "=========================================="
echo "EKS Lab Cleanup Verification"
echo "=========================================="
echo ""

ERRORS=0

# Check EKS clusters
echo "Checking EKS clusters..."
CLUSTERS=$(aws eks list-clusters --region us-east-1 --query 'clusters' --output text 2>/dev/null | grep -c "eks-lab-cluster" || echo "0")
if [ "$CLUSTERS" -gt 0 ]; then
    echo "  ✗ EKS cluster 'eks-lab-cluster' still exists"
    ERRORS=$((ERRORS + 1))
else
    echo "  ✓ No EKS clusters found"
fi

# Check LoadBalancers
echo "Checking LoadBalancers..."
LBS=$(aws elb describe-load-balancers --region us-east-1 --query 'LoadBalancerDescriptions[?contains(LoadBalancerName, `eks`) || contains(LoadBalancerName, `a686`) || contains(LoadBalancerName, `ab8d`)].LoadBalancerName' --output text 2>/dev/null | wc -w)
if [ "$LBS" -gt 0 ]; then
    echo "  ⚠ Found $LBS LoadBalancer(s) (may take a few minutes to delete)"
else
    echo "  ✓ No LoadBalancers found"
fi

# Check kubectl access
echo "Checking kubectl access..."
if kubectl cluster-info &>/dev/null; then
    echo "  ⚠ kubectl still configured (cluster may still exist)"
    ERRORS=$((ERRORS + 1))
else
    echo "  ✓ kubectl not configured (cluster likely deleted)"
fi

# Check IAM roles
echo "Checking IAM roles..."
if aws iam get-role --role-name AmazonEKS_EBS_CSI_DriverRole &>/dev/null; then
    echo "  ⚠ EBS CSI Driver IAM role still exists"
    ERRORS=$((ERRORS + 1))
else
    echo "  ✓ EBS CSI Driver IAM role deleted"
fi

if aws iam get-role --role-name eks-lab-cluster-cluster-role &>/dev/null; then
    echo "  ⚠ EKS cluster IAM role still exists"
    ERRORS=$((ERRORS + 1))
else
    echo "  ✓ EKS cluster IAM role deleted"
fi

# Check Terraform state
echo "Checking Terraform state..."
if [ -f "terraform.tfstate" ] || [ -d ".terraform" ]; then
    STATE_COUNT=$(terraform state list 2>/dev/null | wc -l || echo "0")
    if [ "$STATE_COUNT" -gt 0 ]; then
        echo "  ⚠ Terraform state still contains $STATE_COUNT resources"
        ERRORS=$((ERRORS + 1))
    else
        echo "  ✓ Terraform state is empty"
    fi
else
    echo "  ✓ No Terraform state file found"
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "=========================================="
    echo "✓ Cleanup verification passed!"
    echo "=========================================="
    exit 0
else
    echo "=========================================="
    echo "⚠ Found $ERRORS issue(s) - review above"
    echo "=========================================="
    exit 1
fi

