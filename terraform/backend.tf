# S3 Backend Configuration for Terraform State
# Uses MinIO (S3-compatible storage) running on Proxmox VM
#
# Initial Setup Required:
# 1. Create bucket in MinIO: mc mb myminio/terraform-state
# 2. Enable versioning: mc version enable myminio/terraform-state
# 3. Set credentials in terraform.tfvars or environment variables
# 4. Run: terraform init -migrate-state

terraform {
  backend "s3" {
    # MinIO S3 endpoint
    endpoint = "https://minio-api.elmstreet79.de"
    
    # Bucket and path
    bucket = "terraform-state"
    key    = "homelab/proxmox/terraform.tfstate"
    region = "us-east-1"  # Required but ignored by MinIO
    
    # MinIO-specific settings
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true  # Required for MinIO
    
    # Credentials - DO NOT hardcode here!
    # Option 1: Set via environment variables (recommended):
    #   export AWS_ACCESS_KEY_ID="minio-admin"
    #   export AWS_SECRET_ACCESS_KEY="your-password"
    # Option 2: Add to terraform.tfvars:
    #   minio_access_key = "minio-admin"
    #   minio_secret_key = "your-password"
    # Option 3: Use AWS credentials file (~/.aws/credentials)
  }
}
