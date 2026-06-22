#!/bin/bash
# Fix EKS authentication for demo_devops user on Windows
# Run this from Git Bash with admin AWS credentials

set -e

echo "========================================"
echo "EKS Authentication Fix for Windows"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

CLUSTER_NAME="bookstoreapi-cluster"
REGION="ap-south-1"
IAM_USER_ARN="arn:aws:iam::927120870716:user/demo_devops"

echo "Step 1: Verifying AWS CLI access..."
if ! command -v aws &> /dev/null; then
    echo -e "${RED}✗ AWS CLI is not installed${NC}"
    echo "Install from: https://aws.amazon.com/cli/"
    exit 1
fi

echo -e "${GREEN}✓ AWS CLI found${NC}"
echo ""

echo "Step 2: Checking current AWS identity..."
CURRENT_USER=$(aws sts get-caller-identity --query Arn --output text)
echo "Current IAM identity: $CURRENT_USER"
echo ""

echo "Step 3: Verifying EKS cluster exists..."
if aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" &> /dev/null; then
    echo -e "${GREEN}✓ Cluster '$CLUSTER_NAME' found${NC}"
else
    echo -e "${RED}✗ Cluster '$CLUSTER_NAME' not found in region $REGION${NC}"
    echo ""
    echo "Available clusters:"
    aws eks list-clusters --region "$REGION" --output table
    exit 1
fi
echo ""

echo "Step 4: Updating kubeconfig..."
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
echo -e "${GREEN}✓ Kubeconfig updated${NC}"
echo ""

echo "Step 5: Testing current cluster access..."
if kubectl get nodes &> /dev/null; then
    echo -e "${GREEN}✓ You have admin access to the cluster${NC}"
else
    echo -e "${RED}✗ You don't have access to the cluster${NC}"
    echo ""
    echo "You need to run this script from a machine/account that already has cluster admin access."
    echo "Current user: $CURRENT_USER"
    exit 1
fi
echo ""

echo "Step 6: Backing up current aws-auth ConfigMap..."
BACKUP_FILE="aws-auth-backup-$(date +%Y%m%d-%H%M%S).yaml"
if kubectl get configmap aws-auth -n kube-system -o yaml > "$BACKUP_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓ Backup saved to $BACKUP_FILE${NC}"
else
    echo -e "${YELLOW}⚠ No existing aws-auth ConfigMap found (this is OK for new clusters)${NC}"
fi
echo ""

echo "Step 7: Getting existing mapRoles..."
EXISTING_ROLES=$(kubectl get configmap aws-auth -n kube-system -o jsonpath='{.data.mapRoles}' 2>/dev/null || echo "")

if [ -z "$EXISTING_ROLES" ]; then
    echo -e "${YELLOW}⚠ No existing mapRoles found${NC}"
    echo "Creating new aws-auth ConfigMap..."
    
    # Create new ConfigMap without mapRoles (for clusters without node groups)
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapUsers: |
    - userarn: $IAM_USER_ARN
      username: demo_devops
      groups:
        - system:masters
EOF
else
    echo -e "${GREEN}✓ Found existing mapRoles${NC}"
    echo "Updating aws-auth ConfigMap (preserving existing roles)..."
    
    # Create updated ConfigMap preserving mapRoles
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
$(echo "$EXISTING_ROLES" | sed 's/^/    /')
  mapUsers: |
    - userarn: $IAM_USER_ARN
      username: demo_devops
      groups:
        - system:masters
EOF
fi

echo ""
echo -e "${GREEN}✓ aws-auth ConfigMap updated successfully${NC}"
echo ""

echo "Step 8: Verifying the configuration..."
echo "Current aws-auth ConfigMap:"
kubectl get configmap aws-auth -n kube-system -o yaml
echo ""

echo "Step 9: Testing demo_devops user access..."
echo "To test, set these environment variables and try kubectl:"
echo ""
echo -e "${YELLOW}export AWS_ACCESS_KEY_ID=<demo_devops_access_key>${NC}"
echo -e "${YELLOW}export AWS_SECRET_ACCESS_KEY=<demo_devops_secret_key>${NC}"
echo -e "${YELLOW}export AWS_DEFAULT_REGION=ap-south-1${NC}"
echo -e "${YELLOW}aws eks update-kubeconfig --region ap-south-1 --name $CLUSTER_NAME${NC}"
echo -e "${YELLOW}kubectl get nodes${NC}"
echo ""

echo "========================================"
echo -e "${GREEN}✓ FIX COMPLETE!${NC}"
echo "========================================"
echo ""
echo "The demo_devops user now has admin access to the EKS cluster."
echo "Your GitHub Actions workflow should now work."
echo ""
echo "Next steps:"
echo "1. Commit and push your code"
echo "2. GitHub Actions will automatically deploy"
echo ""
