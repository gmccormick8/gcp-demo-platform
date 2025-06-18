#!/bin/bash
# This script fixes the Workload Identity Provider configuration to allow GitHub Actions to authenticate properly

# Exit on any error
set -e

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "Error: gcloud CLI is not installed. Please install it first."
    exit 1
fi

# Prompt for the GCP project ID if not provided
if [ -z "$PROJECT_ID" ]; then
    read -p "Enter your GCP Project ID: " PROJECT_ID
fi

# Determine which branch/environment we're fixing
if [ -z "$1" ]; then
  echo "Error: You must specify a branch (dev, staging, or prod)"
  echo "Usage: ./fix-workload-identity.sh <branch>"
  exit 1
fi

BRANCH="$1"
if [[ ! "$BRANCH" =~ ^(dev|staging|prod)$ ]]; then
  echo "Error: Branch must be 'dev', 'staging', or 'prod'"
  exit 1
fi

echo "Fixing Workload Identity Provider for $BRANCH environment..."

# Find the current Workload Identity Pool and Provider
echo "Looking for Workload Identity Pool..."
POOL_NAME=$(gcloud iam workload-identity-pools list --project="$PROJECT_ID" --location="global" --filter="displayName~'GitHub Actions Pool - ${BRANCH}'" --format="value(name)")

if [ -z "$POOL_NAME" ]; then
  echo "Error: Could not find a Workload Identity Pool for the $BRANCH environment"
  exit 1
fi

# Extract the pool ID from the full name
POOL_ID=$(echo $POOL_NAME | awk -F'/' '{print $NF}')
echo "Found Workload Identity Pool: $POOL_ID"

# Update the provider to authenticate only from specific repo and branch
echo "Updating the Workload Identity Provider..."
REPO="gmccormick8/gcp-demo-platform"
gcloud iam workload-identity-pools providers update-oidc "github" \
  --project="$PROJECT_ID" \
  --location="global" \
  --workload-identity-pool="$POOL_ID" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.branch=assertion.ref" \
  --attribute-condition="attribute.repository=='${REPO}' && (attribute.branch.startsWith('refs/heads/${BRANCH}') || attribute.branch.endsWith('${BRANCH}'))" \
  --issuer-uri="https://token.actions.githubusercontent.com"

echo "✅ Workload Identity Provider configuration updated successfully!"
echo ""
echo "You can now run your GitHub Actions workflow again. The authentication will now be"
echo "restricted to the ${REPO} repository and ${BRANCH} branch only."
