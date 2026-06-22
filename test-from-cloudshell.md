# Test Commands for AWS CloudShell

Run these in AWS CloudShell to verify everything is working:

```bash
# 1. Verify aws-auth ConfigMap exists and has the right content
kubectl get configmap aws-auth -n kube-system -o yaml

# 2. Check if there are any nodes (there probably aren't any)
kubectl get nodes

# 3. Test authentication - this should work even without nodes
kubectl get namespaces

# 4. Check RBAC permissions
kubectl auth can-i '*' '*' --all-namespaces

# 5. Try to list pods in kube-system
kubectl get pods -n kube-system

# 6. Verify the user mapping
kubectl get configmap aws-auth -n kube-system -o jsonpath='{.data.mapUsers}'
```

**Expected Results:**
- aws-auth should show the demo_devops user mapping
- `kubectl get namespaces` should work (shows default, kube-system, etc.)
- `kubectl auth can-i` should return "yes"
- `kubectl get nodes` might show "No resources found" (that's OK - cluster has no worker nodes)

---

# Then Test from Your Local Machine (Windows)

After confirming CloudShell works, try these locally:

```powershell
# 1. Verify you're using demo_devops credentials
aws sts get-caller-identity

# 2. Update kubeconfig
aws eks update-kubeconfig --region ap-south-1 --name bookstoreapi-cluster

# 3. Test authentication
kubectl get namespaces

# 4. If that works, try these
kubectl get pods -A
kubectl auth can-i get pods --all-namespaces
```

---

# If Local Tests Still Fail

The authentication token might be cached. Try:

```powershell
# Option 1: Force regenerate the token
$env:AWS_STS_REGIONAL_ENDPOINTS = "regional"
kubectl get namespaces

# Option 2: Manually generate a token to test
aws eks get-token --cluster-name bookstoreapi-cluster --region ap-south-1

# Option 3: Delete and recreate kubeconfig
Remove-Item $env:USERPROFILE\.kube\config
aws eks update-kubeconfig --region ap-south-1 --name bookstoreapi-cluster
kubectl get namespaces
```

---

# Alternative: Test Your GitHub Actions

Since the fix is already applied in the cluster, you can just **push your code and let GitHub Actions run**.

The workflow should now pass the "Configure EKS Access" stage!

```bash
git add .
git commit -m "Test EKS authentication fix"
git push
```

Then watch the GitHub Actions workflow - it should work now!
