# Fix EKS Authentication for GitHub Actions

## Problem
The IAM user `demo_devops` is not authorized to access the EKS cluster, causing deployment failures.

## Solution
Add the IAM user to the EKS cluster's aws-auth ConfigMap.

## Prerequisites
1. Install kubectl on your local machine
2. Have AWS CLI configured with admin access to the EKS cluster
3. Have access to modify the EKS cluster

## Steps

### 1. Install kubectl (if not installed)

**Windows PowerShell (as Administrator):**
```powershell
curl.exe -LO "https://dl.k8s.io/release/v1.31.0/bin/windows/amd64/kubectl.exe"
# Move kubectl.exe to C:\Windows\System32 or add to PATH
```

**Or use Chocolatey:**
```powershell
choco install kubernetes-cli
```

### 2. Update kubeconfig
```bash
aws eks update-kubeconfig --region ap-south-1 --name demo-devops
```

### 3. Backup current aws-auth ConfigMap
```bash
kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth-backup.yaml
```

### 4. Get current mapRoles (IMPORTANT!)
```bash
kubectl get configmap aws-auth -n kube-system -o jsonpath='{.data.mapRoles}'
```

Copy the output - you'll need it!

### 5. Create the updated aws-auth ConfigMap

Create a file named `aws-auth-updated.yaml` with this content (replace EXISTING_MAP_ROLES with output from step 4):

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    PASTE_YOUR_EXISTING_MAP_ROLES_HERE
  mapUsers: |
    - userarn: arn:aws:iam::927120870716:user/demo_devops
      username: demo_devops
      groups:
        - system:masters
```

### 6. Apply the updated ConfigMap
```bash
kubectl apply -f aws-auth-updated.yaml
```

### 7. Verify the update
```bash
kubectl get configmap aws-auth -n kube-system -o yaml
```

### 8. Test access
```bash
kubectl get nodes
kubectl get pods -A
```

## Alternative Method (Easier)

If you have `eksctl` installed:

```bash
eksctl create iamidentitymapping \
  --cluster demo-devops \
  --region ap-south-1 \
  --arn arn:aws:iam::927120870716:user/demo_devops \
  --username demo_devops \
  --group system:masters
```

## Verification

After completing the steps, run your GitHub Actions workflow again. The deployment should succeed.

## Troubleshooting

If you still get authentication errors:
1. Check IAM user has `eks:DescribeCluster` permission
2. Verify the ARN in the ConfigMap matches exactly
3. Check EKS cluster security group allows access
4. Ensure AWS credentials in GitHub Secrets are correct

## Security Note

The `system:masters` group gives full cluster admin access. For production, consider using more restrictive RBAC:

```yaml
  mapUsers: |
    - userarn: arn:aws:iam::927120870716:user/demo_devops
      username: demo_devops
      groups:
        - deployers  # Custom group with limited permissions
```

Then create a Role and RoleBinding with only the necessary permissions.
