#!/bin/bash
# EKS Lab Cleanup Script (CloudFormation Edition)
# This script ensures proper cleanup order to avoid resource dependencies

set -e

echo "=========================================="
echo "EKS Lab Cleanup Script (CloudFormation)"
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
    
    # Wait for LoadBalancers to be deleted (they take time)
    echo "  - Waiting for LoadBalancers to be deleted..."
    sleep 30
else
    echo -e "${YELLOW}  Skipping Kubernetes cleanup (kubectl not configured)${NC}"
fi

# Step 2: Delete CloudFormation Stack
echo ""
echo -e "${GREEN}Step 2: Deleting CloudFormation Stack...${NC}"
STACK_NAME="eks-wordpress-lab"

if aws cloudformation describe-stacks --stack-name $STACK_NAME &>/dev/null; then
    echo "  - Deleting stack $STACK_NAME..."
    aws cloudformation delete-stack --stack-name $STACK_NAME
    
    echo "  - Waiting for stack deletion (this may take 10-15 minutes)..."
    aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME
    echo "  ✓ CloudFormation stack deleted"
else
    echo -e "${YELLOW}  Stack $STACK_NAME not found (already deleted)${NC}"
fi

# Step 3: Verify cleanup
echo ""
echo -e "${GREEN}Step 3: Verifying cleanup...${NC}"
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
