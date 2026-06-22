# Test the EKS Authentication Fix in GitHub Actions

## The Fix Has Been Applied!

✅ The `aws-auth` ConfigMap was successfully created in AWS CloudShell  
✅ The `demo_devops` user is now mapped to the cluster with admin permissions

## Now Test It!

### Option 1: Push a Commit (Triggers Workflow Automatically)

```bash
# Make a small change to trigger the workflow
echo "# EKS auth fix applied" >> README.md

# Commit and push
git add .
git commit -m "Test: EKS authentication fix applied"
git push origin main
```

Then go to your GitHub repository → **Actions** tab and watch the workflow run.

---

### Option 2: Manually Trigger the Workflow

1. Go to your GitHub repository
2. Click the **Actions** tab
3. Select your workflow ("BookStore API CI/CD Pipeline")
4. Click **"Run workflow"** button
5. Select branch: `main`
6. Click **"Run workflow"**

---

## What to Watch For

The workflow should now **PASS** these stages:

### ✅ Stage 3.2: Configure EKS Access
**Previously Failed Here** ❌  
**Should Now Pass** ✅

Expected output:
```
✓ EKS access verified successfully

Cluster nodes:
No resources found
(This is OK - cluster has no worker nodes yet)

Checking permissions...
yes
```

### ⚠️ Stage 3.3: Deploy to EKS  
**Will likely still fail** because you need worker nodes for actual deployment

But that's a different issue - at least authentication will work!

---

## If Stage 3.2 Still Fails

**Check these in AWS CloudShell:**

```bash
# Verify aws-auth ConfigMap
kubectl get configmap aws-auth -n kube-system -o yaml

# Check if demo_devops user is listed
kubectl get configmap aws-auth -n kube-system -o jsonpath='{.data.mapUsers}' | grep demo_devops

# Test authentication works from CloudShell
kubectl auth can-i '*' '*' --all-namespaces
```

If CloudShell shows the user but GitHub Actions still fails, the issue might be with the GitHub Secrets (AWS credentials).

---

## Next Problem: Worker Nodes

Once authentication works, you'll need to add worker nodes to deploy your app:

```bash
# Create a node group
aws eks create-nodegroup \
  --cluster-name bookstoreapi-cluster \
  --nodegroup-name bookstore-nodes \
  --region ap-south-1 \
  --node-role arn:aws:iam::927120870716:role/EKSNodeRole \
  --subnets subnet-xxxxx subnet-yyyyy \
  --scaling-config minSize=1,maxSize=3,desiredSize=2 \
  --instance-types t3.medium
```

But let's solve one problem at a time! First test if authentication works.

---

## Expected GitHub Actions Output (Success)

```
Stage 3.2: Configure EKS Access
========================================
Verifying AWS Identity...
========================================
IAM User ARN: arn:aws:iam::927120870716:user/demo_devops
Account ID: 927120870716

========================================
Configuring kubectl for EKS cluster...
========================================
Updated context arn:aws:eks:ap-south-1:927120870716:cluster/bookstoreapi-cluster
Current kubeconfig context:
arn:aws:eks:ap-south-1:927120870716:cluster/bookstoreapi-cluster

========================================
Testing EKS Cluster Access...
========================================
Client Version: v1.36.2
Kustomize Version: v5.8.1

Attempting to access cluster...
✓ EKS access verified successfully

Cluster nodes:
No resources found

Checking permissions...
yes
```

**✅ SUCCESS!** The workflow passes this stage!
