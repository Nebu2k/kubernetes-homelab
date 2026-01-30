#!/bin/bash
# MinIO Bucket Setup for Terraform State
# Run this script BEFORE migrating the Terraform state

set -e

# MinIO Configuration
MINIO_ALIAS="homelab"
MINIO_ENDPOINT="https://minio-api.elmstreet79.de"
MINIO_USER="minio-admin"
MINIO_PASSWORD="${MINIO_PASSWORD:-}"  # Read from environment
BUCKET_NAME="terraform-state"

# Check if mc is installed
if ! command -v mc &> /dev/null; then
    echo "❌ MinIO Client (mc) is not installed."
    echo "Install with: brew install minio/stable/mc"
    exit 1
fi

# Prompt for password if not set
if [ -z "$MINIO_PASSWORD" ]; then
    read -s -p "Enter MinIO admin password: " MINIO_PASSWORD
    echo
fi

echo "🔧 Setting up MinIO backend for Terraform..."

# Configure MinIO alias
echo "📝 Configuring MinIO client..."
mc alias set $MINIO_ALIAS $MINIO_ENDPOINT $MINIO_USER $MINIO_PASSWORD --insecure

# Create bucket
echo "🪣 Creating bucket: $BUCKET_NAME"
if mc mb ${MINIO_ALIAS}/${BUCKET_NAME} 2>/dev/null; then
    echo "✅ Bucket created successfully"
else
    echo "⚠️  Bucket already exists (this is fine)"
fi

# Enable versioning (important for state recovery)
echo "🔄 Enabling versioning..."
mc version enable ${MINIO_ALIAS}/${BUCKET_NAME}

# Verify setup
echo ""
echo "✅ MinIO backend setup complete!"
echo ""
echo "Bucket info:"
mc ls ${MINIO_ALIAS}/${BUCKET_NAME}
echo ""
echo "Next steps:"
echo "1. Set environment variables:"
echo "   export AWS_ACCESS_KEY_ID=\"minio-admin\""
echo "   export AWS_SECRET_ACCESS_KEY=\"your-password\""
echo ""
echo "2. Initialize Terraform with migration:"
echo "   cd $(dirname $0)"
echo "   terraform init -migrate-state"
echo ""
echo "3. Verify state is stored remotely:"
echo "   mc ls ${MINIO_ALIAS}/${BUCKET_NAME}"
