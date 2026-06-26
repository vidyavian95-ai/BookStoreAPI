#!/bin/bash
# Script to set up Terraform backend (S3 + DynamoDB)
# Run this ONCE before using the main Terraform configuration

set -e

echo "================================================"
echo "Terraform Backend Setup for BookStoreAPI"
echo "================================================"
echo ""

# Configuration
BUCKET_NAME="bookstoreapi-terraform-state"
DYNAMODB_TABLE="bookstoreapi-terraform-locks"
AWS_REGION="ap-south-1"

echo "Configuration:"
echo "  S3 Bucket: $BUCKET_NAME"
echo "  DynamoDB Table: $DYNAMODB_TABLE"
echo "  Region: $AWS_REGION"
echo ""

# Check if AWS CLI is configured
echo "Checking AWS credentials..."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ Error: AWS credentials not configured"
    echo "Run: aws configure"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "✓ AWS Account ID: $ACCOUNT_ID"
echo ""

# Check if S3 bucket exists
echo "Checking if S3 bucket exists..."
if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    echo "Creating S3 bucket: $BUCKET_NAME"
    
    # Create bucket
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$AWS_REGION" \
        --create-bucket-configuration LocationConstraint="$AWS_REGION"
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled
    
    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }'
    
    # Block public access
    aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
            BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
    
    # Add lifecycle policy
    aws s3api put-bucket-lifecycle-configuration \
        --bucket "$BUCKET_NAME" \
        --lifecycle-configuration '{
            "Rules": [
                {
                    "ID": "delete-old-versions",
                    "Status": "Enabled",
                    "Filter": {"Prefix": ""},
                    "NoncurrentVersionExpiration": {
                        "NoncurrentDays": 90
                    }
                },
                {
                    "ID": "abort-incomplete-uploads",
                    "Status": "Enabled",
                    "Filter": {"Prefix": ""},
                    "AbortIncompleteMultipartUpload": {
                        "DaysAfterInitiation": 7
                    }
                }
            ]
        }'
    
    # Add tags
    aws s3api put-bucket-tagging \
        --bucket "$BUCKET_NAME" \
        --tagging 'TagSet=[
            {Key=Name,Value="Terraform State Bucket"},
            {Key=Environment,Value=Production},
            {Key=ManagedBy,Value=Terraform}
        ]'
    
    echo "✓ S3 bucket created and configured"
else
    echo "✓ S3 bucket already exists"
fi
echo ""

# Check if DynamoDB table exists
echo "Checking if DynamoDB table exists..."
if ! aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION" > /dev/null 2>&1; then
    echo "Creating DynamoDB table: $DYNAMODB_TABLE"
    
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$AWS_REGION" \
        --tags Key=Name,Value="Terraform State Lock Table" \
               Key=Environment,Value=Production \
               Key=ManagedBy,Value=Terraform
    
    echo "Waiting for table to become active..."
    aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION"
    
    echo "✓ DynamoDB table created"
else
    echo "✓ DynamoDB table already exists"
fi
echo ""

echo "================================================"
echo "✓ Backend setup complete!"
echo "================================================"
echo ""
echo "Backend Configuration:"
echo "----------------------"
echo "terraform {"
echo "  backend \"s3\" {"
echo "    bucket         = \"$BUCKET_NAME\""
echo "    key            = \"eks/terraform.tfstate\""
echo "    region         = \"$AWS_REGION\""
echo "    encrypt        = true"
echo "    dynamodb_table = \"$DYNAMODB_TABLE\""
echo "  }"
echo "}"
echo ""
echo "Next Steps:"
echo "1. Ensure backend.tf is configured with the above settings"
echo "2. Run: terraform init -migrate-state"
echo "3. Run: terraform plan"
echo "4. Run: terraform apply"
echo ""
echo "State file will be stored at:"
echo "  s3://$BUCKET_NAME/eks/terraform.tfstate"
echo ""
