#!/bin/bash
# Fix EKS authentication for demo_devops user

echo "Configuring kubectl for EKS cluster..."
aws eks update-kubeconfig --region ap-south-1 --name demo-devops

echo "Backing up current aws-auth ConfigMap..."
kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth-backup-$(date +%Y%m%d-%H%M%S).yaml 2>/dev/null || echo "No existing aws-auth found, will create new one"

echo "Applying updated aws-auth ConfigMap..."
cat <<EOF | kubectl apply -f -
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

echo "Verifying the configuration..."
kubectl get configmap aws-auth -n kube-system -o yaml

echo "Testing access..."
kubectl auth can-i get pods

echo "Done! demo_devops user now has admin access to the EKS cluster"
