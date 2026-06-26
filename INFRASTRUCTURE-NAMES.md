# Infrastructure Resource Names

This document lists all the standardized resource names used across the BookStoreAPI infrastructure.

## AWS Configuration

- **AWS Region:** `ap-south-1`
- **AWS Account ID:** `927120870716`

## Terraform Infrastructure

### ECR (Elastic Container Registry)
- **Repository Name:** `bookstoreapi`
- **Full Repository URL:** `927120870716.dkr.ecr.ap-south-1.amazonaws.com/bookstoreapi`
- **Image Tags:**
  - Latest: `927120870716.dkr.ecr.ap-south-1.amazonaws.com/bookstoreapi:latest`
  - Commit SHA: `927120870716.dkr.ecr.ap-south-1.amazonaws.com/bookstoreapi:<git-sha>`

### EKS (Elastic Kubernetes Service)
- **Cluster Name:** `bookstoreapi-eks-cluster`
- **Kubernetes Version:** `1.30`
- **Node Group Name:** `nodes`
- **Node Instance Type:** `t3.small`
- **Node Count:** 2-3 nodes (min: 2, desired: 2, max: 3)

### VPC & Networking
- **VPC Name:** `bookstoreapi-vpc`
- **VPC CIDR:** `10.0.0.0/16`
- **Availability Zones:** `ap-south-1a`, `ap-south-1b`
- **Private Subnets:** `10.0.1.0/24`, `10.0.2.0/24`
- **Public Subnets:** `10.0.101.0/24`, `10.0.102.0/24`

### IAM Roles
- **ECR Access Role:** `bookstoreapi-ecr-access-role`
- **Node Group Role:** `bookstoreapi-node-role`

### State Management
- **S3 Bucket:** `bookstoreapi-terraform-state`
- **State File Path:** `s3://bookstoreapi-terraform-state/eks/terraform.tfstate`
- **DynamoDB Lock Table:** `bookstoreapi-terraform-locks`

## Kubernetes Resources

### Deployment
- **Deployment Name:** `bookstoreapi`
- **Namespace:** `default`
- **Replicas:** 3
- **Container Name:** `bookstoreapi`
- **Container Port:** 8080

### Service
- **Service Name:** `bookstoreapi`
- **Service Type:** `LoadBalancer` or `ClusterIP` (check service.yaml)
- **Target Port:** 8080

### Ingress
- **Ingress Name:** `bookstoreapi-ingress`
- **Host:** (configure as needed)

## GitHub Actions CI/CD

### Workflow Names
- **Main CI/CD:** `BookStore API CI/CD Pipeline` (`.github/workflows/ci.yml`)
- **Terraform CI/CD:** `Terraform CI/CD` (`.github/workflows/ci-terraform.yml`)

### Docker Image Build
- **Build Context:** Repository root
- **Dockerfile:** `./dockerfile`
- **Image Name:** `bookstoreapi`
- **Registry:** `927120870716.dkr.ecr.ap-south-1.amazonaws.com`
- **Full Image Path:** `927120870716.dkr.ecr.ap-south-1.amazonaws.com/bookstoreapi:latest`

### Required GitHub Secrets
- `AWS_ACCESS_KEY_ID` - AWS access key for deployments
- `AWS_SECRET_ACCESS_KEY` - AWS secret key for deployments
- `SONAR_TOKEN` - SonarQube authentication token

## Important Commands

### AWS CLI Commands

```bash
# Login to ECR
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 927120870716.dkr.ecr.ap-south-1.amazonaws.com

# Configure kubectl for EKS
aws eks update-kubeconfig --region ap-south-1 --name bookstoreapi-eks-cluster

# List ECR images
aws ecr list-images --repository-name bookstoreapi --region ap-south-1

# Describe EKS cluster
aws eks describe-cluster --name bookstoreapi-eks-cluster --region ap-south-1
```

### Docker Commands

```bash
# Build image
docker build -t bookstoreapi:latest .

# Tag image for ECR
docker tag bookstoreapi:latest 927120870716.dkr.ecr.ap-south-1.amazonaws.com/bookstoreapi:latest

# Push to ECR
docker push 927120870716.dkr.ecr.ap-south-1.amazonaws.com/bookstoreapi:latest
```

### Kubernetes Commands

```bash
# Apply deployment
kubectl apply -f deployment/deployment.yaml

# Apply service
kubectl apply -f deployment/service.yaml

# Apply ingress
kubectl apply -f deployment/ingress.yaml

# Check deployment status
kubectl get deployment bookstoreapi -n default

# Check pods
kubectl get pods -n default -l app=bookstoreapi

# Check service
kubectl get service bookstoreapi -n default

# View logs
kubectl logs -f deployment/bookstoreapi -n default
```

### Terraform Commands

```bash
# Initialize with remote backend
cd terraform
terraform init -upgrade

# Plan infrastructure changes
terraform plan

# Apply infrastructure changes
terraform apply

# View outputs
terraform output

# Get ECR URL
terraform output ecr_repository_url

# Get EKS cluster name
terraform output eks_cluster_name
```

## Configuration Files Reference

| File | Resource Name | Value |
|------|---------------|-------|
| `terraform/variables.tf` | `ecr_repository_name` | `bookstoreapi` |
| `terraform/variables.tf` | `cluster_name` | `bookstoreapi-eks-cluster` |
| `terraform/variables.tf` | `project_name` | `bookstoreapi` |
| `.github/workflows/ci.yml` | `REPOSITORY` | `bookstoreapi` |
| `.github/workflows/ci.yml` | EKS cluster name | `bookstoreapi-eks-cluster` |
| `deployment/deployment.yaml` | image | `927120870716.dkr.ecr.ap-south-1.amazonaws.com/bookstoreapi:latest` |
| `deployment/deployment.yaml` | deployment name | `bookstoreapi` |

## Naming Conventions

- **Project Name:** `bookstoreapi` (lowercase, no hyphens)
- **Cluster Name:** `bookstoreapi-eks-cluster` (project-eks-cluster format)
- **Node Group:** `nodes` (simple, descriptive)
- **IAM Roles:** `bookstoreapi-<purpose>-role` (project-purpose-role format)
- **S3 Buckets:** `bookstoreapi-<purpose>` (project-purpose format)
- **DynamoDB Tables:** `bookstoreapi-<purpose>` (project-purpose format)

## Verification Checklist

- [ ] ECR repository name matches across Terraform and CI/CD
- [ ] EKS cluster name matches in Terraform, CI/CD, and kubectl commands
- [ ] Docker image paths are consistent in deployment.yaml and CI/CD
- [ ] AWS region is set to `ap-south-1` everywhere
- [ ] GitHub Secrets are configured with correct AWS credentials
- [ ] Terraform backend (S3 + DynamoDB) is created
- [ ] All resource names follow the naming conventions

## Last Updated

**Date:** 2026-06-26  
**Updated By:** Infrastructure automation  
**Version:** 1.0
