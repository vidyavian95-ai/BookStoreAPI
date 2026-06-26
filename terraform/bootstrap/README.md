# Terraform Backend Bootstrap

This directory contains the **one-time setup** files for creating the S3 bucket and DynamoDB table for Terraform state management.

## ⚠️ Important

**Run this BEFORE initializing the main Terraform infrastructure.**

These files should **NOT** be run together with the main infrastructure. They create the backend resources that the main infrastructure will use.

## Usage

### Option 1: Use the Shell Script (Recommended)

```bash
cd terraform/bootstrap
chmod +x setup-backend.sh
./setup-backend.sh
```

### Option 2: Use Terraform

```bash
cd terraform/bootstrap
terraform init
terraform apply
```

### Option 3: Manual AWS CLI Commands

See the commands in `setup-backend.sh` for manual creation.

## What Gets Created

- **S3 Bucket:** `bookstoreapi-terraform-state`
  - Versioning enabled
  - Encryption enabled (AES256)
  - Public access blocked
  - Lifecycle policies configured

- **DynamoDB Table:** `bookstoreapi-terraform-locks`
  - Pay-per-request billing
  - Used for state locking

## After Setup

Once the backend resources are created:

1. Go back to the main terraform directory:
   ```bash
   cd ..
   ```

2. Initialize Terraform with the remote backend:
   ```bash
   terraform init -migrate-state
   ```

3. Continue with normal Terraform workflow:
   ```bash
   terraform plan
   terraform apply
   ```

## Cleanup

⚠️ **Only delete these resources if you're completely done with the infrastructure!**

Deleting the S3 bucket will delete your state file, making it impossible to manage your infrastructure with Terraform.

```bash
cd terraform/bootstrap
terraform destroy
```
