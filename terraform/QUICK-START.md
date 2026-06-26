# Terraform Quick Start Guide

## 🎯 Goal
Deploy ECR (Container Registry) and EKS (Kubernetes Cluster) using Terraform with automated CI/CD and secure state management.

## ⚡ Quick Setup (5 Steps)

### 1️⃣ Setup Backend (One-Time)
```bash
cd terraform
chmod +x setup-backend.sh
./setup-backend.sh
```

This creates:
- S3 bucket: `bookstoreapi-terraform-state`
- DynamoDB table: `bookstoreapi-terraform-locks`

### 2️⃣ Initialize Terraform
```bash
terraform init -migrate-state
```
Type `yes` when prompted.

### 3️⃣ Add AWS Credentials to GitHub
Go to: **GitHub Repo → Settings → Secrets → Actions**

Add:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

### 4️⃣ Test Locally
```bash
terraform plan
terraform apply  # Takes 15-20 minutes
```

### 5️⃣ Push to GitHub
```bash
git add .
git commit -m "Add Terraform infrastructure"
git push origin main
```

GitHub Actions will automatically deploy on future pushes! 🎉

## 📊 What Gets Created?

- ✅ ECR repository for Docker images
- ✅ EKS cluster (Kubernetes v1.30)
- ✅ VPC with public/private subnets
- ✅ 2 worker nodes (t3.small)
- ✅ IAM roles and security groups

## 🔄 How State Management Works

### Local Development:
```
Your Computer → S3 (bookstoreapi-terraform-state)
                ↓
            DynamoDB (locks)
```

### CI/CD Pipeline:
```
GitHub Actions → S3 (bookstoreapi-terraform-state)
                 ↓
             DynamoDB (locks)
```

**Both use the same state file!** Changes are automatically synced.

## 🚀 CI/CD Workflow

### On Pull Request:
- ✅ Validates Terraform
- ✅ Runs plan
- ✅ Comments plan on PR

### On Push to Main:
- ✅ Validates
- ✅ Plans
- ✅ **Applies automatically**

### Manual Actions:
1. Go to **Actions** tab
2. Select **"Terraform CI/CD"**
3. Click **"Run workflow"**
4. Choose: `plan`, `apply`, or `destroy`

## 📁 Important Files

```
terraform/
├── main.tf              # Infrastructure definition
├── backend.tf           # S3 state configuration
├── variables.tf         # Configuration options
├── outputs.tf           # Results after apply
└── setup-backend.sh     # Backend setup script

.github/workflows/
└── ci-terraform.yml     # CI/CD pipeline
```

## 🔐 State File Location

**Remote State:**
```
s3://bookstoreapi-terraform-state/eks/terraform.tfstate
```

**Lock Table:**
```
DynamoDB: bookstoreapi-terraform-locks
```

## 💡 Common Commands

```bash
# View all resources
terraform state list

# View specific resource
terraform state show aws_eks_cluster.main

# Pull state locally (read-only)
terraform state pull > current.tfstate

# Force unlock if stuck
terraform force-unlock <LOCK_ID>

# View outputs
terraform output
```

## 🎯 After Deployment

### Configure kubectl:
```bash
aws eks update-kubeconfig --region ap-south-1 --name bookstoreapi-cluster
kubectl get nodes
```

### Login to ECR:
```bash
# Get ECR URL from output
terraform output ecr_repository_url

# Login
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin <ecr-url>
```

### Deploy Application:
```bash
docker build -t bookstoreapi .
docker tag bookstoreapi:latest <ecr-url>:latest
docker push <ecr-url>:latest
kubectl apply -f deployment/
```

## 💰 Cost

- **State Storage:** < $1/month (S3 + DynamoDB)
- **Infrastructure:** ~$137/month (EKS + nodes + networking)

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| "Backend initialization failed" | Run `setup-backend.sh` first |
| "Access Denied" | Check AWS credentials |
| "State Lock Timeout" | Wait or run `terraform force-unlock <ID>` |
| GitHub Actions failing | Verify GitHub Secrets are set |

## 📚 More Info

- Full setup guide: `TERRAFORM-CICD-SETUP.md`
- State management details: `STATEFILE-SETUP.md`
- Infrastructure details: `README.md`

## ✅ Checklist

- [ ] Backend created (S3 + DynamoDB)
- [ ] Terraform initialized with remote state
- [ ] AWS credentials in GitHub Secrets
- [ ] Local `terraform apply` successful
- [ ] Pushed to GitHub
- [ ] GitHub Actions workflow passed
- [ ] kubectl configured
- [ ] Application deployed

---

**Ready to deploy?** Start with step 1️⃣ above!
