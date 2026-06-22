#!/bin/bash
# Run this in AWS CloudShell to verify and fix the aws-auth ConfigMap

echo "=========================================="
echo "Verifying aws-auth ConfigMap"
echo "=========================================="
echo ""

# First, let's see what we have
echo "Current aws-auth ConfigMap:"
kubectl get configmap aws-auth -n kube-system -o yaml

echo ""
echo "=========================================="
echo "Checking if nodes need roles..."
echo "=========================================="

# Check if there are worker nodes
NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
echo "Number of nodes in cluster: $NODE_COUNT"

if [ "$NODE_COUNT" -gt 0 ]; then
  echo ""
  echo "Nodes found! We need to add node instance role to aws-auth."
  echo ""
  
  # Get the node instance role ARN
  echo "Getting node instance role ARN..."
  INSTANCE_ROLE_ARN=$(aws iam list-roles --query 'Roles[?contains(RoleName, `NodeInstanceRole`) || contains(RoleName, `nodegroup`)].Arn' --output text | head -n 1)
  
  if [ -n "$INSTANCE_ROLE_ARN" ]; then
    echo "Found node role: $INSTANCE_ROLE_ARN"
    echo ""
    echo "Updating aws-auth with both user and node roles..."
    
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: $INSTANCE_ROLE_ARN
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
  mapUsers: |
    - userarn: arn:aws:iam::927120870716:user/demo_devops
      username: demo_devops
      groups:
        - system:masters
EOF
    
    echo ""
    echo "✓ Updated aws-auth with node roles"
  else
    echo "⚠ No node instance role found. Cluster might not have worker nodes yet."
  fi
else
  echo "No worker nodes found. The current configuration should be fine."
  echo "Worker nodes will be able to join when they're created."
fi

echo ""
echo "=========================================="
echo "Final aws-auth ConfigMap:"
echo "=========================================="
kubectl get configmap aws-auth -n kube-system -o yaml

echo ""
echo "=========================================="
echo "Testing kubectl access:"
echo "=========================================="
kubectl auth can-i '*' '*' --all-namespaces && echo "✓ Full admin access confirmed" || echo "✗ Limited access"

echo ""
echo "Done! Now test from your local machine with demo_devops credentials:"
echo "  kubectl get nodes"
