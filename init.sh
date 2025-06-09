#!/bin/bash
# This script sets up the environment 
#usage: bash setup.sh or ./setup.sh

# Exit immediately if a command exits with a non-zero status. 
set -e

echo "Setting up the environment..."

# Check if Project ID is set
if [ ! -z "$DEVSHELL_PROJECT_ID" ]; then
  export PROJECT_ID=$DEVSHELL_PROJECT_ID
  echo "Using Cloud Shell Project ID: $PROJECT_ID"
elif [ ! -z "$PROJECT_ID" ]; then
  echo "Using provided Project ID: $PROJECT_ID"
  
  api_array=(
    "compute.googleapis.com"
    "iam.googleapis.com"
    "iamcredentials.googleapis.com"
    "cloudresourcemanager.googleapis.com"
  )

  for api in "${api_array[@]}"; do
    echo "Enabling API: $api"
    gcloud services enable "$api" --project="${PROJECT_ID}"
  done

  # Set variables
  BRANCH="prod"
  POOL_NAME="github-pool-${BRANCH}"
  PROVIDER_NAME="github"
  SERVICE_ACCOUNT_NAME="github-actions-sa-${BRANCH}"
  REPO="gmccormick8/gcp-demo-platform"

  # Create Workload Identity Pool
  echo "Creating Workload Identity Pool..."
  gcloud iam workload-identity-pools create "${POOL_NAME}" \
    --project="${PROJECT_ID}" \
    --location="global" \
    --display-name="GitHub Actions Pool - ${BRANCH}"

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

  # Output important information
  echo "Setup completed. Please note down the following values for GitHub Actions:"
  echo "Workload Identity Provider: ${POOL_ID}/providers/${PROVIDER_NAME}"
  echo "Service Account: ${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
else
  echo "Error: PROJECT_ID is not set. Please set the PROJECT_ID environment variable or run from Google Cloud Console."
  exit 1
fi