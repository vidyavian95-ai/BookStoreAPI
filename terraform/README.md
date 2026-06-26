# BookStoreAPI Terraform Infrastructure

This Terraform configuration provisions the following AWS resources:
- **ECR (Elastic Container Registry)** - For Docker image storage
- **EKS (Elastic Kubernetes Service)** - Kubernetes cluster
- **VPC** - Virtual Private Cloud with public/private subnets
- **IAM Roles** - For ECR and EKS access

## Prerequisites

1. **Install Terraform**
   ```bash
   # Windows (using Chocolatey)
   choco install terraform
   
   # Or download from: https://www.terraform.io/downloads
   ```

2. **Install AWS CLI**
   ```bash
   # Verify installation
   aws --version
   ```

3. **Configure AWS Credentials** (SECURE METHOD)
   ```bash
   # Option 1: Using AWS CLI (Recommended)
   aws configure
   
   # Option 2: Environment Variables
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_DEFAULT_REGION="ap-south-1"
   
   # Windows PowerShell
   $env:AWS_ACCESS_KEY_ID="your-access-key"
   $env:AWS_SECRET_ACCESS_KEY="your-secret-key"
   $env:AWS_DEFAULT_REGION="ap-south-1"
   ```

## Usage

### 0. Setup Remote State Backend (One-Time Setup)

**Important:** Set up S3 backend for state management before running Terraform.

```bash
# Navigate to bootstrap directory
cd terraform/bootstrap

# Option 1: Use the automated script
chmod +x setup-backend.sh
./setup-backend.sh

# Option 2: Manual setup using Terraform
terraform init
terraform apply

# Go back to main terraform directory
cd ..
```

This creates:
- S3 bucket: `bookstoreapi-terraform-state` (for state storage)
- DynamoDB table: `bookstoreapi-terraform-locks` (for state locking)

See `bootstrap/README.md` or `STATEFILE-SETUP.md` for detailed information.

### 1. Initialize Terraform with Remote Backend

```bash
cd terraform
terraform init -migrate-state
```

When prompted, type `yes` to migrate existing state to S3.

### 2. Create terraform.tfvars (Optional)

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values (optional - defaults are provided)
```

### 3. Review the Plan

```bash
terraform plan
```

### 4. Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted. This will take **15-20 minutes** to provision all resources.

### 5. Configure kubectl

After successful apply, run the command from the output:

```bash
aws eks update-kubeconfig --region ap-south-1 --name bookstoreapi-cluster
```

### 6. Verify the Cluster

```bash
kubectl get nodes
kubectl get namespaces
```

### 7. Login to ECR

Use the command from terraform output:

```bash
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin <ecr-url>
```

## Important Outputs

After `terraform apply`, you'll get these important outputs:
- `ecr_repository_url` - Your ECR repository URL
- `eks_cluster_endpoint` - Your EKS cluster endpoint
- `configure_kubectl` - Command to configure kubectl
- `ecr_login_command` - Command to login to ECR

View outputs anytime:
```bash
terraform output
```

## Cost Estimation

**Approximate monthly costs (ap-south-1 region):**
- EKS Cluster: ~$73/month
- 2x t3.small nodes: ~$30/month
- NAT Gateway: ~$33/month
- ECR storage: $0.10/GB/month
- **Total: ~$136-150/month**

## Destroying Resources

⚠️ **WARNING: This will delete all resources!**

```bash
terraform destroy
```

## Security Best Practices

1. **NEVER hardcode credentials** in Terraform files
2. **NEVER commit** `terraform.tfvars` or `*.tfstate` files to git
3. Use AWS credentials from:
   - Environment variables
   - AWS credentials file (~/.aws/credentials)
   - IAM roles (when running on EC2)
4. Enable MFA on your AWS account
5. Use least-privilege IAM policies

## Troubleshooting

### Issue: "Error: error configuring Terraform AWS Provider"
**Solution**: Check your AWS credentials are correctly configured

### Issue: "Error creating EKS Cluster: InvalidParameterException"
**Solution**: Ensure you have proper IAM permissions

### Issue: Nodes not joining cluster
**Solution**: Check security groups and subnet configurations

## Project Structure

```
terraform/
├── main.tf                    # Main infrastructure definition
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── terraform.tfvars.example   # Example variables (safe to commit)
├── .gitignore                 # Ignore sensitive files
└── README.md                  # This file
```

## Next Steps

After infrastructure is provisioned:

1. **Build and push Docker image:**
   ```bash
   docker build -t bookstoreapi .
   docker tag bookstoreapi:latest <ecr-url>:latest
   docker push <ecr-url>:latest
   ```

2. **Deploy to Kubernetes:**
   ```bash
   kubectl apply -f deployment/deployment.yaml
   kubectl apply -f deployment/service.yaml
   kubectl apply -f deployment/ingress.yaml
   ```

3. **Monitor deployment:**
   ```bash
   kubectl get pods
   kubectl get services
   kubectl logs -f <pod-name>
   ```

## Support

For issues or questions, refer to:
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [ECR User Guide](https://docs.aws.amazon.com/ecr/latest/userguide/)
