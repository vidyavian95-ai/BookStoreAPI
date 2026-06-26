# Terraform CI/CD Setup Guide

Complete guide to set up Terraform with GitHub Actions CI/CD and remote state management.

## 📋 Overview

This setup includes:
- ✅ Terraform infrastructure for ECR + EKS
- ✅ Remote state management (S3 + DynamoDB)
- ✅ GitHub Actions CI/CD pipeline
- ✅ Automated validation, planning, and deployment
- ✅ State locking to prevent concurrent modifications
- ✅ Pull request comments with Terraform plans

## 🚀 Quick Start

### Step 1: Setup AWS Credentials in GitHub

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Add these secrets:

   ```
   Name: AWS_ACCESS_KEY_ID
   Value: <your-aws-access-key>
   
   Name: AWS_SECRET_ACCESS_KEY
   Value: <your-aws-secret-key>
   ```

### Step 2: Setup Terraform Backend (One-Time)

This creates S3 bucket and DynamoDB table for state management.

**Option A: Using Script (Recommended)**

```bash
cd terraform
chmod +x setup-backend.sh
./setup-backend.sh
```

**Option B: Manual Setup**

```bash
# Create S3 bucket
aws s3api create-bucket \
  --bucket bookstoreapi-terraform-state \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket bookstoreapi-terraform-state \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket bookstoreapi-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket bookstoreapi-terraform-state \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name bookstoreapi-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-south-1
```

### Step 3: Initialize Terraform Locally

```bash
cd terraform
terraform init -migrate-state
```

When asked "Do you want to copy existing state to the new backend?", type `yes`.

### Step 4: Test Terraform Locally

```bash
terraform plan
```

Verify the plan looks correct. The state is now stored in S3!

### Step 5: Push to GitHub

```bash
git add .
git commit -m "Add Terraform infrastructure with CI/CD"
git push origin main
```

## 🔄 CI/CD Workflow

The GitHub Actions workflow (`.github/workflows/ci-terraform.yml`) automatically:

### On Pull Request:
1. ✅ Validates Terraform syntax
2. ✅ Runs `terraform plan`
3. ✅ Comments the plan on the PR

### On Push to Main:
1. ✅ Validates Terraform
2. ✅ Runs `terraform plan`
3. ✅ Runs `terraform apply` (auto-approved)
4. ✅ Outputs results

### Manual Workflow Dispatch:
- **Plan**: Run plan without applying
- **Apply**: Apply infrastructure changes
- **Destroy**: Destroy all infrastructure (⚠️ requires approval)

## 📊 Workflow Triggers

```yaml
# Automatic triggers
push:
  branches: [main, develop]
  paths: ['terraform/**']

pull_request:
  branches: [main, develop]
  paths: ['terraform/**']

# Manual trigger
workflow_dispatch:
  inputs:
    action: [plan, apply, destroy]
```

## 🔐 State Management

### Where is State Stored?

**Remote State (Production):**
- **Location:** `s3://bookstoreapi-terraform-state/eks/terraform.tfstate`
- **Locking:** DynamoDB table `bookstoreapi-terraform-locks`
- **Encryption:** AES256
- **Versioning:** Enabled (90-day retention)

### State Locking

When Terraform runs, it:
1. Acquires a lock in DynamoDB
2. Performs operations
3. Releases the lock

**This prevents concurrent modifications!**

If someone else is running Terraform:
```
Error: Error acquiring the state lock
Lock Info:
  ID:        abc-123-def
  Who:       user@hostname
  Created:   2024-01-15 10:30:45
```

### View State

```bash
# List all resources
terraform state list

# Show specific resource
terraform state show aws_eks_cluster.main

# Pull state locally (read-only)
terraform state pull > current.tfstate
```

### Force Unlock (Emergency)

```bash
terraform force-unlock <LOCK_ID>
```

## 📁 File Structure

```
terraform/
├── main.tf                    # Main infrastructure (ECR, EKS, VPC)
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── backend.tf                 # S3 backend configuration
├── setup-backend.tf           # Bootstrap S3 + DynamoDB
├── setup-backend.sh           # Automated backend setup script
├── terraform.tfvars.example   # Example configuration
├── .gitignore                 # Ignore sensitive files
├── README.md                  # Usage documentation
└── STATEFILE-SETUP.md         # Detailed state management guide

.github/workflows/
└── ci-terraform.yml           # GitHub Actions workflow
```

## 🎯 Usage Examples

### Create Infrastructure

```bash
# Local
cd terraform
terraform plan
terraform apply

# GitHub Actions (automatic on push to main)
git push origin main
```

### Update Infrastructure

```bash
# 1. Make changes to .tf files
# 2. Create a pull request
# 3. GitHub Actions will comment with the plan
# 4. Merge PR → automatic apply
```

### Manual Apply via GitHub

1. Go to **Actions** tab in GitHub
2. Select **"Terraform CI/CD"** workflow
3. Click **"Run workflow"**
4. Select action: **Apply**
5. Click **"Run workflow"**

### Destroy Infrastructure

1. Go to **Actions** tab in GitHub
2. Select **"Terraform CI/CD"** workflow
3. Click **"Run workflow"**
4. Select action: **Destroy**
5. Approve the destruction (requires environment approval)

## 🔧 Configuration

### Customize Variables

Create `terraform/terraform.tfvars`:

```hcl
aws_region          = "ap-south-1"
cluster_name        = "my-cluster"
kubernetes_version  = "1.30"
node_instance_type  = "t3.medium"
node_desired_size   = 3
```

### Environment Protection

The workflow uses GitHub Environments for protection:

1. Go to **Settings** → **Environments**
2. Create environment: `production`
3. Add required reviewers
4. Now all applies to `production` require approval

## 📊 Monitoring

### View Workflow Runs

1. Go to **Actions** tab
2. Click on a workflow run
3. View logs for each job

### Terraform Outputs

After successful apply, outputs are shown in the workflow summary:
- ECR repository URL
- EKS cluster endpoint
- kubectl configuration command
- ECR login command

## 🐛 Troubleshooting

### Issue: "Backend initialization failed"

```bash
Error: Failed to get existing workspaces: S3 bucket does not exist
```

**Solution:** Run Step 2 to create the S3 bucket first.

### Issue: "Access Denied"

```bash
Error: error using credentials to get account ID
```

**Solution:** 
1. Check AWS credentials are correct
2. Verify IAM permissions include S3, DynamoDB, EC2, EKS

### Issue: "State Lock Timeout"

```bash
Error: Error acquiring the state lock
```

**Solution:**
```bash
# Wait or force unlock
terraform force-unlock <LOCK_ID>
```

### Issue: "GitHub Actions Failing"

**Check:**
1. AWS credentials are added as GitHub Secrets
2. Secret names match: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
3. IAM user has proper permissions

## 🔒 Security Best Practices

### ✅ DO:
- Use GitHub Secrets for AWS credentials
- Enable MFA on AWS account
- Use environment protection rules
- Review Terraform plans before applying
- Use least-privilege IAM policies
- Enable S3 bucket versioning and encryption

### ❌ DON'T:
- Hardcode credentials in `.tf` files
- Commit `terraform.tfvars` or `.tfstate` files
- Share AWS credentials publicly
- Disable state locking
- Skip plan review before apply

## 💰 Cost Estimation

**State Management:**
- S3 storage: < $0.50/month
- DynamoDB: < $0.50/month

**Infrastructure (EKS + ECR):**
- EKS Cluster: ~$73/month
- 2x t3.small nodes: ~$30/month
- NAT Gateway: ~$33/month
- ECR storage: $0.10/GB/month

**Total: ~$137/month**

## 📚 Additional Resources

- [Terraform S3 Backend Docs](https://developer.hashicorp.com/terraform/language/settings/backends/s3)
- [GitHub Actions for Terraform](https://developer.hashicorp.com/terraform/tutorials/automation/github-actions)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform State Management](https://developer.hashicorp.com/terraform/language/state)

## ✅ Checklist

- [ ] AWS credentials configured locally
- [ ] AWS credentials added to GitHub Secrets
- [ ] S3 bucket created for state
- [ ] DynamoDB table created for locking
- [ ] `terraform init -migrate-state` completed
- [ ] Local `terraform plan` successful
- [ ] Pushed to GitHub
- [ ] GitHub Actions workflow passed
- [ ] Infrastructure deployed successfully

## 🎉 Next Steps

After infrastructure is deployed:

1. **Configure kubectl:**
   ```bash
   aws eks update-kubeconfig --region ap-south-1 --name bookstoreapi-cluster
   ```

2. **Login to ECR:**
   ```bash
   aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin <ecr-url>
   ```

3. **Build and push Docker image:**
   ```bash
   docker build -t bookstoreapi .
   docker tag bookstoreapi:latest <ecr-url>:latest
   docker push <ecr-url>:latest
   ```

4. **Deploy to Kubernetes:**
   ```bash
   kubectl apply -f deployment/
   ```

---

**Questions or issues?** Check the `STATEFILE-SETUP.md` for detailed state management information.
