#!/bin/bash
# FINAL EKS Authentication Fix
# Copy and run this ENTIRE script in AWS CloudShell

set -e

CLUSTER_NAME="bookstoreapi-cluster"
REGION="ap-south-1"
IAM_USER_ARN="arn:aws:iam::927120870716:user/demo_devops"

echo "=========================================="
echo "EKS Authentication Fix - Final Version"
echo "=========================================="
echo ""

# Step 1: Update kubeconfig
echo "[1/6] Updating kubeconfig..."
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
echo "✓ Done"
echo ""

# Step 2: Test current access
echo "[2/6] Testing current access from CloudShell..."
if kubectl get namespaces &> /dev/null; then
    echo "✓ You have cluster access from CloudShell"
else
    echo "✗ You don't have cluster access"
    echo "You need to be logged in as the user who created the cluster"
    exit 1
fi
echo ""

# Step 3: Backup existing aws-auth (if exists)
echo "[3/6] Backing up existing aws-auth ConfigMap..."
if kubectl get configmap aws-auth -n kube-system &> /dev/null; then
    kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth-backup-$(date +%Y%m%d-%H%M%S).yaml
    echo "✓ Backup created"
    
    # Get existing mapRoles
    EXISTING_ROLES=$(kubectl get configmap aws-auth -n kube-system -o jsonpath='{.data.mapRoles}' 2>/dev/null || echo "")
else
    echo "✓ No existing aws-auth (will create new one)"
    EXISTING_ROLES=""
fi
echo ""

# Step 4: Create/Update aws-auth ConfigMap
echo "[4/6] Creating/Updating aws-auth ConfigMap..."

if [ -n "$EXISTING_ROLES" ]; then
    # Preserve existing roles
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
else
    # Create without roles (OK for serverless or Fargate clusters)
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
fi

echo "✓ aws-auth ConfigMap updated"
echo ""

# Step 5: Verify the configuration
echo "[5/6] Verifying configuration..."
echo ""
echo "Current aws-auth ConfigMap:"
kubectl get configmap aws-auth -n kube-system -o yaml
echo ""

if kubectl get configmap aws-auth -n kube-system -o yaml | grep -q "demo_devops"; then
    echo "✓ demo_devops user is configured"
else
    echo "✗ demo_devops user NOT found!"
    exit 1
fi
echo ""

# Step 6: Test authentication
echo "[6/6] Testing authentication..."
kubectl auth can-i '*' '*' --all-namespaces
echo ""

echo "=========================================="
echo "✓✓✓ FIX COMPLETE! ✓✓✓"
echo "=========================================="
echo ""
echo "The demo_devops user now has admin access to the cluster."
echo ""
echo "NEXT STEPS:"
echo "1. Go back to your Windows machine"
echo "2. Run: kubectl get namespaces"
echo "3. If still failing, wait 1-2 minutes and try again"
echo "4. Push your code to trigger GitHub Actions"
echo ""
