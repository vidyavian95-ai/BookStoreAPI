# EKS Authentication Fix - Applied

## Date: June 22, 2026

## What Was Done

✅ Added IAM user `demo_devops` to EKS cluster `bookstoreapi-cluster`  
✅ Created aws-auth ConfigMap in kube-system namespace  
✅ Granted system:masters permissions to demo_devops user

## Fix Applied Via

AWS CloudShell with admin credentials:

```bash
aws eks update-kubeconfig --region ap-south-1 --name bookstoreapi-cluster

kubectl apply -f - <<EOF
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
```

## Result

`configmap/aws-auth created` ✅

## Expected Impact

- GitHub Actions CI/CD pipeline should now pass the "Configure EKS Access" stage
- `demo_devops` IAM user can now execute kubectl commands against the cluster
- Deployments from CI/CD will be authorized

## Next Steps

1. ✅ Test GitHub Actions workflow
2. ⏭️ Add worker nodes to the EKS cluster for actual pod deployment
3. ⏭️ Deploy the BookStore API application

## Verification

To verify from CloudShell:
```bash
kubectl get configmap aws-auth -n kube-system -o yaml
kubectl auth can-i '*' '*' --all-namespaces
```

Expected: Both commands should work without authentication errors.
