# Terraform Backend Configuration
# This file configures remote state storage in S3 with DynamoDB for state locking

terraform {
  backend "s3" {
    bucket         = "bookstoreapi-terraform-state"
    key            = "eks/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "bookstoreapi-terraform-locks"
    
    # Optional: Use KMS for encryption
    # kms_key_id = "arn:aws:kms:ap-south-1:ACCOUNT_ID:key/KEY_ID"
  }
}
