#!/bin/bash
# Script to verify cleanup is complete (CloudFormation Edition)

echo "=========================================="
echo "EKS Lab Cleanup Verification"
echo "=========================================="
echo ""

ERRORS=0

# Check EKS clusters
echo "Checking EKS clusters..."
CLUSTERS=$(aws eks list-clusters --region us-east-1 --query 'clusters' --output text 2>/dev/null | grep -c "eks-lab-cluster-cfn" || echo "0")
if [ "$CLUSTERS" -gt 0 ]; then
    echo "  ✗ EKS cluster 'eks-lab-cluster-cfn' still exists"
    ERRORS=$((ERRORS + 1))
else
    echo "  ✓ No EKS clusters found"
fi

# Check LoadBalancers
echo "Checking LoadBalancers..."
LBS=$(aws elb describe-load-balancers --region us-east-1 --query 'LoadBalancerDescriptions[?contains(LoadBalancerName, `eks`)].LoadBalancerName' --output text 2>/dev/null | wc -w)
if [ "$LBS" -gt 0 ]; then
    echo "  ⚠ Found $LBS LoadBalancer(s) (may take a few minutes to delete)"
else
    echo "  ✓ No LoadBalancers found"
fi

# Check CloudFormation Stack
echo "Checking CloudFormation Stack..."
if aws cloudformation describe-stacks --stack-name eks-wordpress-lab &>/dev/null; then
    echo "  ⚠ CloudFormation stack 'eks-wordpress-lab' still exists"
    ERRORS=$((ERRORS + 1))
else
    echo "  ✓ CloudFormation stack deleted"
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
