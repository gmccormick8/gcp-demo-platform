#!/bin/bash
# This script sets up the GCP environment for GitHub Actions integration using Workload Identity Federation.
# Requirements:
#   - GCloud CLI installed and initialized
#   - Valid GCP project with billing enabled
#   - Project Owner or Editor permissions
# Usage: bash init.sh or ./init.sh

# Exit immediately if a command exits with a non-zero status. 
set -e

echo "Setting up the environment..."

# Check and set PROJECT_ID
if [ -n "$DEVSHELL_PROJECT_ID" ]; then
  export PROJECT_ID="$DEVSHELL_PROJECT_ID"
  echo "Using Cloud Shell Project ID: '$PROJECT_ID'"
elif [ -z "$PROJECT_ID" ]; then
  echo "Error: PROJECT_ID is not set. Please set the PROJECT_ID environment variable or run from Google Cloud Console."
  exit 1
fi

echo "Using Project ID: '$PROJECT_ID'"

# Check for branch parameter
if [ -z "$1" ]; then
  echo "Error: Branch parameter is required (dev, staging, or prod)"
  echo "Usage: ./init.sh <branch>"
  exit 1
fi

BRANCH="$1"
if [[ ! "$BRANCH" =~ ^(dev|staging|prod)$ ]]; then
  echo "Error: Branch must be 'dev', 'staging', or 'prod'"
  exit 1
fi

# Main script logic
api_array=(
  "compute.googleapis.com"
  "iam.googleapis.com"
  "iamcredentials.googleapis.com"
  "cloudresourcemanager.googleapis.com"
  "storage.googleapis.com"
)

for api in "${api_array[@]}"; do
  echo "Enabling API: $api"
  gcloud services enable "$api" --project="$PROJECT_ID"
done

# Set variables
random_number=$((RANDOM % 99999 + 0))
POOL_NAME="${BRANCH}-github-pool-${random_number}"
PROVIDER_NAME="github"
SERVICE_ACCOUNT_NAME="github-actions-sa-${BRANCH}"
REPO="gmccormick8/gcp-demo-platform"

# Create Workload Identity Pool
echo "Creating Workload Identity Pool..."
gcloud iam workload-identity-pools create "${POOL_NAME}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="GitHub Actions Pool - ${BRANCH}"

# Wait for the pool to be created
sleep 15

# Get the Workload Identity Pool ID
POOL_ID=$(gcloud iam workload-identity-pools describe "${POOL_NAME}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --format="value(name)")

# Create Workload Identity Provider
echo "Creating Workload Identity Provider..."
gcloud iam workload-identity-pools providers create-oidc "${PROVIDER_NAME}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="${POOL_NAME}" \
  --display-name="GitHub Actions Provider - ${BRANCH}" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-condition="attribute.ref=='refs/heads/${BRANCH}' && attribute.repository=='${REPO}'"

# Create Service Account
echo "Creating Service Account..."
gcloud iam service-accounts create "${SERVICE_ACCOUNT_NAME}" \
  --project="${PROJECT_ID}" \
  --display-name="GitHub Actions Service Account - ${BRANCH}"

# Wait for the service account to be created
sleep 10

# Grant necessary roles to the service account
echo "Granting roles..."
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.workloadIdentityUser"

# Allow authentication from GitHub Actions
echo "Setting up Workload Identity Federation..."
gcloud iam service-accounts add-iam-policy-binding "${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${POOL_ID}/attribute.repository/${REPO}?attribute.ref=refs/heads/${BRANCH}"

# Create Terraform state bucket
BUCKET_NAME="${BRANCH}-tf-state-${PROJECT_ID}"
echo "Creating Terraform state bucket..."
gcloud storage buckets create gs://"${BUCKET_NAME}" \
  --project="${PROJECT_ID}" \
  --public-access-prevention \
  --uniform-bucket-level-access \
  --versioning 

# Output important information
echo ""
echo "================================================================"
echo "                   SETUP COMPLETED SUCCESSFULLY                    "
echo "================================================================"
echo ""
echo " IMPORTANT: Save these values for GitHub Actions and Terraform State configuration:"
echo ""
echo " Project ID:"
echo "   ${PROJECT_ID}"
echo ""
echo " Workload Identity Provider:"
echo "   ${POOL_ID}/providers/${PROVIDER_NAME}"
echo ""
echo " Service Account:"
echo "   ${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
echo ""
echo " Terraform State Bucket:"
echo "   ${BUCKET_NAME}"
echo ""
echo "================================================================"