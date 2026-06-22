#!/bin/bash
# Complete EKS Access Fix Script
# Run this in AWS CloudShell with admin credentials

set -e

CLUSTER_NAME="bookstoreapi-cluster"
REGION="ap-south-1"
IAM_USER_ARN="arn:aws:iam::927120870716:user/demo_devops"

echo "=========================================="
echo "EKS Access Configuration Script"
echo "=========================================="
echo ""

# Update kubeconfig
echo "Step 1: Updating kubeconfig..."
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
echo "✓ Kubeconfig updated"
echo ""

# Check if aws-auth exists
echo "Step 2: Checking aws-auth ConfigMap..."
if kubectl get configmap aws-auth -n kube-system &> /dev/null; then
    echo "✓ aws-auth ConfigMap exists"
    
    # Check if demo_devops is already there
    if kubectl get configmap aws-auth -n kube-system -o yaml | grep -q "demo_devops"; then
        echo "✓ demo_devops user is already configured"
        echo ""
        echo "Current configuration:"
        kubectl get configmap aws-auth -n kube-system -o yaml
    else
        echo "⚠ demo_devops user NOT found, adding it now..."
        
        # Get existing mapRoles if any
        EXISTING_ROLES=$(kubectl get configmap aws-auth -n kube-system -o jsonpath='{.data.mapRoles}' 2>/dev/null || echo "")
        
        if [ -n "$EXISTING_ROLES" ]; then
            # Update with existing roles
            kubectl apply -f - <<EOF
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
            # Create without roles
            kubectl apply -f - <<EOF
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
        echo "✓ demo_devops user added"
    fi
else
    echo "⚠ aws-auth ConfigMap does not exist, creating it..."
    kubectl apply -f - <<EOF
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
    echo "✓ aws-auth ConfigMap created"
fi

echo ""
echo "Step 3: Verifying configuration..."
kubectl get configmap aws-auth -n kube-system -o yaml

echo ""
echo "Step 4: Testing authentication..."
kubectl auth can-i get pods --all-namespaces

echo ""
echo "Step 5: Checking for worker nodes..."
NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
echo "Number of worker nodes: $NODE_COUNT"

if [ "$NODE_COUNT" -eq 0 ]; then
    echo ""
    echo "⚠ WARNING: No worker nodes found!"
    echo "Your cluster has no nodes to run pods."
    echo ""
    echo "To add nodes, create a node group:"
    echo ""
    echo "aws eks create-nodegroup \\"
    echo "  --cluster-name $CLUSTER_NAME \\"
    echo "  --nodegroup-name bookstore-workers \\"
    echo "  --region $REGION \\"
    echo "  --node-role <YOUR_NODE_ROLE_ARN> \\"
    echo "  --subnets <SUBNET_ID_1> <SUBNET_ID_2> \\"
    echo "  --scaling-config minSize=1,maxSize=3,desiredSize=2 \\"
    echo "  --instance-types t3.medium"
    echo ""
else
    echo "✓ Found $NODE_COUNT worker node(s)"
    kubectl get nodes
fi

echo ""
echo "=========================================="
echo "✓ Configuration Complete!"
echo "=========================================="
echo ""
echo "The demo_devops user now has access to the cluster."
echo "GitHub Actions should work now."
echo ""
echo "Test locally with:"
echo "  kubectl get namespaces"
echo "  kubectl get pods -A"
