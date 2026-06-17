#!/bin/bash
# Script to add IAM user to EKS cluster aws-auth ConfigMap

# Get current aws-auth configmap
kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth-backup.yaml

# Create patch to add the IAM user
cat <<EOF > aws-auth-patch.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapUsers: |
    - userarn: arn:aws:iam::927120870716:user/demo_devops
      username: demo_devops
      groups:
        - system:masters
EOF

# Apply the patch
kubectl apply -f aws-auth-patch.yaml

echo "IAM user demo_devops has been added to EKS cluster with admin permissions"
