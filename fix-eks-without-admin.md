# Fix EKS Access Without Admin Access

## The Problem
You're stuck in a catch-22:
- You need kubectl access to grant kubectl access
- The `demo_devops` user can't access the cluster yet
- You don't have another admin account available

## Solutions (Pick One)

---

### Solution 1: Use the AWS Root Account or IAM Admin User

The cluster was just created today (June 22, 2026). Whoever created it has automatic admin access.

**Find out who created it:**
```bash
aws cloudtrail lookup-events --region ap-south-1 \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=bookstoreapi-cluster \
  --max-items 1
```

**Then:**
1. Log in with that account
2. Run the fix script: `./fix-eks-auth-windows.sh`

---

### Solution 2: Use an EC2 Instance with Admin Role

Create an EC2 instance with a role that has EKS admin permissions:

1. **Create IAM Role for EC2:**
   - Go to IAM → Roles → Create Role
   - Select "EC2" as trusted entity
   - Attach policies: `AmazonEKSClusterPolicy`, `AmazonEKSWorkerNodePolicy`
   - Name it: `EKS-Admin-Role`

2. **Launch EC2 Instance:**
   ```bash
   aws ec2 run-instances \
     --image-id ami-0c55b159cbfafe1f0 \
     --instance-type t2.micro \
     --iam-instance-profile Name=EKS-Admin-Role \
     --region ap-south-1 \
     --key-name your-key-pair
   ```

3. **SSH into the instance and run:**
   ```bash
   # Install kubectl
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   chmod +x kubectl
   sudo mv kubectl /usr/local/bin/

   # Configure cluster access
   aws eks update-kubeconfig --region ap-south-1 --name bookstoreapi-cluster

   # Apply the fix
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

4. **Terminate the instance** (optional, once done)

---

### Solution 3: Use AWS CloudShell (Easiest!)

AWS CloudShell comes with kubectl pre-installed and uses your current IAM permissions.

**Steps:**

1. **Log into AWS Console** (https://console.aws.amazon.com)
   - Make sure you're logged in as an admin user

2. **Open CloudShell:**
   - Click the CloudShell icon (>_) in the top navigation bar
   - Or go to: https://console.aws.amazon.com/cloudshell

3. **Run these commands in CloudShell:**
   ```bash
   # Update kubeconfig
   aws eks update-kubeconfig --region ap-south-1 --name bookstoreapi-cluster
   
   # Test access
   kubectl get nodes
   
   # If that works, apply the fix
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
   
   # Verify
   kubectl get configmap aws-auth -n kube-system -o yaml
   ```

4. **Test from your local machine:**
   ```bash
   kubectl get nodes
   ```

---

### Solution 4: Grant Permissions via AWS IAM Directly (Advanced)

If you have IAM admin permissions, you can create a role and assume it:

1. **Create a file `eks-admin-trust-policy.json`:**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "AWS": "arn:aws:iam::927120870716:user/demo_devops"
         },
         "Action": "sts:AssumeRole"
       }
     ]
   }
   ```

2. **Create the role:**
   ```bash
   aws iam create-role \
     --role-name EKS-Admin-Emergency \
     --assume-role-policy-document file://eks-admin-trust-policy.json
   ```

3. **Attach EKS permissions:**
   ```bash
   aws iam attach-role-policy \
     --role-name EKS-Admin-Emergency \
     --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
   ```

4. **Assume the role:**
   ```bash
   aws sts assume-role \
     --role-arn arn:aws:iam::927120870716:role/EKS-Admin-Emergency \
     --role-session-name eks-admin-session
   ```

5. **Use the temporary credentials to fix aws-auth**

---

## Which Solution Should I Use?

| Solution | Difficulty | Requirements | Best For |
|----------|-----------|--------------|----------|
| **Root/Admin Account** | ⭐ Easy | Access to the account that created the cluster | If you know who created it |
| **AWS CloudShell** | ⭐⭐ Easy | AWS Console access with admin role | Quickest fix if you have console access |
| **EC2 Instance** | ⭐⭐⭐ Medium | Ability to create EC2 + IAM role | If you can't access console but have AWS CLI admin |
| **IAM Role Assumption** | ⭐⭐⭐⭐ Hard | Deep IAM knowledge | Advanced users only |

---

## After Running Any Solution

Test the fix:
```bash
kubectl get nodes
```

You should see your cluster nodes! Then run your GitHub Actions workflow again.

---

## Still Stuck?

**Option: Contact the AWS account owner** and ask them to run this single command:

```bash
aws eks update-kubeconfig --region ap-south-1 --name bookstoreapi-cluster && \
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

That's it! One command solves everything.
