# Terraform State File Management

This guide explains how to set up and manage Terraform state files securely using AWS S3 and DynamoDB.

## Why Remote State?

**Problems with local state:**
- ❌ Not suitable for team collaboration
- ❌ No state locking (concurrent runs can corrupt state)
- ❌ Risk of losing state file
- ❌ Sensitive data stored locally
- ❌ No versioning or backup

**Benefits of S3 backend:**
- ✅ Centralized state storage
- ✅ State locking via DynamoDB (prevents concurrent modifications)
- ✅ Versioning enabled (can rollback)
- ✅ Encrypted at rest
- ✅ Automatic backups
- ✅ Team collaboration ready

## Setup Process

### Step 1: Create S3 Bucket and DynamoDB Table

This is a **one-time setup** to create the infrastructure for storing Terraform state.

```bash
cd terraform

# Initialize and apply the backend setup
terraform init
terraform apply -target=aws_s3_bucket.terraform_state -target=aws_dynamodb_table.terraform_locks

# Or create a separate directory for backend setup
mkdir backend-setup
cd backend-setup
cp ../setup-backend.tf .
terraform init
terraform apply
```

**What this creates:**
- S3 bucket: `bookstoreapi-terraform-state`
- DynamoDB table: `bookstoreapi-terraform-locks`

### Step 2: Migrate to Remote Backend

After the S3 bucket and DynamoDB table are created, configure the backend in your main Terraform code.

The `backend.tf` file is already configured:

```hcl
terraform {
  backend "s3" {
    bucket         = "bookstoreapi-terraform-state"
    key            = "eks/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "bookstoreapi-terraform-locks"
  }
}
```

**Initialize with the backend:**

```bash
cd terraform
terraform init -migrate-state
```

Terraform will ask: `Do you want to copy existing state to the new backend?`
- Type `yes` to migrate existing local state to S3
- Type `no` to start fresh

### Step 3: Verify Remote State

```bash
# List objects in S3 bucket
aws s3 ls s3://bookstoreapi-terraform-state/eks/

# Check DynamoDB table
aws dynamodb describe-table --table-name bookstoreapi-terraform-locks
```

## State File Location

Your state files are now stored at:
- **S3 Path:** `s3://bookstoreapi-terraform-state/eks/terraform.tfstate`
- **Lock Table:** DynamoDB table `bookstoreapi-terraform-locks`

## State Locking

When you run `terraform apply`, Terraform will:
1. Acquire a lock in DynamoDB
2. Perform the operation
3. Release the lock

**If another user tries to run Terraform simultaneously:**
```
Error: Error acquiring the state lock
Lock Info:
  ID:        a1b2c3d4-5678-90ab-cdef-1234567890ab
  Path:      bookstoreapi-terraform-state/eks/terraform.tfstate
  Operation: OperationTypeApply
  Who:       user@hostname
  Version:   1.6.0
  Created:   2024-01-15 10:30:45.123456789 +0000 UTC
```

## Useful Commands

### View Remote State
```bash
terraform state list
terraform state show <resource_name>
```

### Pull State Locally (Read-only)
```bash
terraform state pull > current.tfstate
```

### Force Unlock (If Lock is Stuck)
```bash
# Get Lock ID from error message
terraform force-unlock <LOCK_ID>
```

### State Versioning
S3 versioning is enabled. To see all versions:
```bash
aws s3api list-object-versions \
  --bucket bookstoreapi-terraform-state \
  --prefix eks/terraform.tfstate
```

### Restore Previous State Version
```bash
# List versions
aws s3api list-object-versions \
  --bucket bookstoreapi-terraform-state \
  --prefix eks/terraform.tfstate

# Restore specific version
aws s3api get-object \
  --bucket bookstoreapi-terraform-state \
  --key eks/terraform.tfstate \
  --version-id <VERSION_ID> \
  restored-state.tfstate

# Then manually upload if needed
```

## GitHub Actions Integration

The CI/CD pipeline (`ci-terraform.yml`) automatically:
1. Uses remote state from S3
2. Acquires lock before operations
3. Releases lock after completion
4. Handles state conflicts

**Required GitHub Secrets:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## Security Best Practices

### 1. Bucket Encryption
✅ Already enabled with AES256 encryption

### 2. Versioning
✅ Already enabled - keeps 90 days of old versions

### 3. Access Control
The S3 bucket has:
- ✅ Public access blocked
- ✅ Encryption enabled
- ✅ Versioning enabled
- ✅ Lifecycle policies configured

### 4. IAM Permissions Required

Your AWS user/role needs these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::bookstoreapi-terraform-state/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": "arn:aws:s3:::bookstoreapi-terraform-state"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:ap-south-1:*:table/bookstoreapi-terraform-locks"
    }
  ]
}
```

## Disaster Recovery

### Backup State Manually
```bash
# Download current state
aws s3 cp s3://bookstoreapi-terraform-state/eks/terraform.tfstate ./backup-$(date +%Y%m%d).tfstate

# Or use terraform
terraform state pull > backup-$(date +%Y%m%d).tfstate
```

### Restore from Backup
```bash
# Push to S3
aws s3 cp backup-20240115.tfstate s3://bookstoreapi-terraform-state/eks/terraform.tfstate

# Then run
terraform refresh
```

## Cost

**S3 Storage:** ~$0.023 per GB/month (very small - state files are typically < 1MB)
**DynamoDB:** Pay-per-request pricing (minimal cost - only used during Terraform runs)

**Estimated monthly cost:** < $0.50/month

## Troubleshooting

### Issue: Backend initialization failed
```bash
Error: Failed to get existing workspaces: S3 bucket does not exist
```
**Solution:** Run Step 1 to create the S3 bucket first

### Issue: State lock timeout
```bash
Error: Error acquiring the state lock
```
**Solution:** Wait for other operations to complete, or force unlock:
```bash
terraform force-unlock <LOCK_ID>
```

### Issue: Access denied
```bash
Error: error using credentials to get account ID: error calling sts:GetCallerIdentity
```
**Solution:** Check your AWS credentials have proper permissions

## Team Workflow

1. **Pull latest code:**
   ```bash
   git pull origin main
   ```

2. **Run Terraform:**
   ```bash
   cd terraform
   terraform init  # Gets latest state from S3
   terraform plan
   terraform apply
   ```

3. **Commit changes:**
   ```bash
   git add .
   git commit -m "Update infrastructure"
   git push origin main
   ```

4. **CI/CD automatically:**
   - Runs on every push to `main`
   - Uses same S3 backend
   - Applies changes automatically

## Alternative: Terraform Cloud

For even more features, consider [Terraform Cloud](https://cloud.hashicorp.com/products/terraform) which provides:
- Remote state management (like S3)
- State locking
- Private module registry
- Policy as code
- Cost estimation
- Free tier available

## Next Steps

1. ✅ Create S3 bucket and DynamoDB table (Step 1)
2. ✅ Configure backend in `backend.tf`
3. ✅ Run `terraform init -migrate-state`
4. ✅ Add AWS credentials to GitHub Secrets
5. ✅ Push to GitHub - CI/CD will use remote state
6. ✅ Verify state is in S3
7. ✅ Delete local `terraform.tfstate` file (now redundant)

## References

- [Terraform S3 Backend Documentation](https://developer.hashicorp.com/terraform/language/settings/backends/s3)
- [State Locking Documentation](https://developer.hashicorp.com/terraform/language/state/locking)
- [AWS S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
