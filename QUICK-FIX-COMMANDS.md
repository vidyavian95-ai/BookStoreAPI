# ⚡ Quick Fix Commands for Windows

Run these commands in Git Bash (as someone who already has EKS admin access):

## Option 1: Automated Script (Recommended)

```bash
# Make the script executable
chmod +x fix-eks-auth-windows.sh

# Run the script
./fix-eks-auth-windows.sh
```

---

## Option 2: Manual Commands (Step-by-Step)

### Step 1: Verify you have access
```bash
aws eks update-kubeconfig --region ap-south-1 --name bookstoreapi-cluster
kubectl get nodes
```

If you can see nodes, you have admin access. Continue to Step 2.

If you get "Unauthorized", you need to run these commands from a different AWS account that has cluster admin access.

---

### Step 2: Backup the current configuration
```bash
kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth-backup.yaml
```

---

### Step 3: Check if aws-auth ConfigMap exists
```bash
kubectl get configmap aws-auth -n kube-system
```

---

### Step 4A: If aws-auth EXISTS, update it
```bash
# Get current mapRoles (IMPORTANT!)
kubectl get configmap aws-auth -n kube-system -o jsonpath='{.data.mapRoles}' > existing-roles.txt

# Show the roles (you'll need to copy them)
cat existing-roles.txt
```

Create a file `aws-auth-updated.yaml` with this content:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    # PASTE THE CONTENT FROM existing-roles.txt HERE
    # DO NOT SKIP THIS - YOUR NODES NEED THESE ROLES!
  mapUsers: |
    - userarn: arn:aws:iam::927120870716:user/demo_devops
      username: demo_devops
      groups:
        - system:masters
```

Apply it:
```bash
kubectl apply -f aws-auth-updated.yaml
```

---

### Step 4B: If aws-auth DOES NOT EXIST, create it
```bash
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
```

---

### Step 5: Verify the change
```bash
kubectl get configmap aws-auth -n kube-system -o yaml
```

You should see the demo_devops user in the mapUsers section.

---

### Step 6: Test with demo_devops credentials

In a NEW terminal window (or set these variables):

```bash
export AWS_ACCESS_KEY_ID=your_demo_devops_key
export AWS_SECRET_ACCESS_KEY=your_demo_devops_secret
export AWS_DEFAULT_REGION=ap-south-1

aws eks update-kubeconfig --region ap-south-1 --name bookstoreapi-cluster
kubectl get nodes
```

If you see nodes, it works! ✅

---

## Option 3: One-Line Quick Fix (RISKY - Only if no existing aws-auth)

⚠️ **WARNING: Only use if you're sure there's no existing aws-auth ConfigMap!**

```bash
kubectl create configmap aws-auth -n kube-system \
  --from-literal=mapUsers="- userarn: arn:aws:iam::927120870716:user/demo_devops
  username: demo_devops
  groups:
    - system:masters"
```

---

## Troubleshooting

### "error: You must be logged in to the server (Unauthorized)"
→ You need to run these from an AWS account that already has cluster access.
→ Check which account you're using: `aws sts get-caller-identity`

### "Error from server (NotFound): configmaps 'aws-auth' not found"
→ This is OK for new clusters. Use **Option 4B** above to create it.

### "The connection to the server localhost:8080 was refused"
→ kubectl is not configured. Run:
```bash
aws eks update-kubeconfig --region ap-south-1 --name bookstoreapi-cluster
```

### How do I know what cluster name to use?
```bash
aws eks list-clusters --region ap-south-1
```

### After the fix, GitHub Actions still fails
→ Make sure your GitHub Secrets have the correct AWS credentials for demo_devops
→ Trigger a new workflow run (don't just re-run the failed job)

---

## After the Fix

Once this is done:

1. **Commit your code** (if you have changes)
2. **Push to GitHub**
3. **GitHub Actions will automatically run** and should now succeed at the "Configure EKS Access" stage

Or manually trigger the workflow:
- Go to your GitHub repository
- Click "Actions" tab
- Select your workflow
- Click "Run workflow"

---

## What We Just Did

We added the IAM user `demo_devops` to the EKS cluster's authorization list by updating the `aws-auth` ConfigMap in the `kube-system` namespace.

This tells EKS: "When someone authenticates as the IAM user demo_devops, give them admin access to the cluster."

Now your GitHub Actions workflow (which uses demo_devops credentials) can deploy to the cluster.
