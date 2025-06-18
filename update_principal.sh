#!/bin/bash
# This script updates the Workload Identity Federation principal format
# without re-running the entire initialization process.
# 
# Usage: ./update_principal.sh <branch>
# - branch: dev, staging, or prod

set -e

echo "==============================================================="
echo "    Updating GCP Workload Identity Federation Principal        "
echo "==============================================================="

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
  echo "Usage: ./update_principal.sh <branch>"
  exit 1
fi

BRANCH="$1"
if [[ ! "$BRANCH" =~ ^(dev|staging|prod)$ ]]; then
  echo "Error: Branch must be 'dev', 'staging', or 'prod'"
  exit 1
fi

# Set variables
REPO="gmccormick8/gcp-demo-platform"
SA_NAME="terraform-${BRANCH}-sa"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# List all workload identity pools to find the one for this branch
echo "Finding Workload Identity Pool for branch: ${BRANCH}..."
POOL_DESCRIPTION=$(gcloud iam workload-identity-pools list --location=global --format="json" --filter="displayName:'GitHub Actions Pool - ${BRANCH}'" | jq -r '.[0]')

if [ -z "$POOL_DESCRIPTION" ] || [ "$POOL_DESCRIPTION" == "null" ]; then
  echo "Error: Could not find Workload Identity Pool for branch ${BRANCH}."
  echo "Please ensure the initialization script was run previously."
  exit 1
fi

# Extract the pool ID and name
POOL_NAME=$(echo $POOL_DESCRIPTION | jq -r '.name' | awk -F'/' '{print $NF}')
POOL_ID=$(echo $POOL_DESCRIPTION | jq -r '.name')

echo "Found Workload Identity Pool: ${POOL_NAME}"

# Find the provider
PROVIDER_NAME="github"

# Define the old and new principal formats
OLD_PRINCIPAL="principal://iam.googleapis.com/${POOL_ID}/subject/repo:${REPO}:ref:refs/heads/${BRANCH}"
NEW_PRINCIPAL="principalSet://iam.googleapis.com/${POOL_ID}/attribute.repository_id/999072242/attribute.workflow_ref/gmccormick8\/gcp-demo-platform\/.github\/workflows\/deploy.yml@refs\/heads\/${BRANCH}/attribute.environment/${BRANCH}/attribute.actor_id/74574750"

echo "Updating Workload Identity Federation Principal format..."

# Get the current bindings
echo "Checking current IAM policy binding for service account: ${SA_EMAIL}..."
CURRENT_POLICY=$(gcloud iam service-accounts get-iam-policy ${SA_EMAIL} --format=json)

# Check if the old principal exists in the policy
if echo "$CURRENT_POLICY" | grep -q "$OLD_PRINCIPAL"; then
  echo "Found old principal format. Updating..."
  
  # Remove the old binding
  echo "Removing old principal binding..."
  gcloud iam service-accounts remove-iam-policy-binding "${SA_EMAIL}" \
    --member="${OLD_PRINCIPAL}" \
    --role="roles/iam.workloadIdentityUser"
  
  # Add the new binding
  echo "Adding new principal binding..."
  gcloud iam service-accounts add-iam-policy-binding "${SA_EMAIL}" \
    --member="${NEW_PRINCIPAL}" \
    --role="roles/iam.workloadIdentityUser"
  
  echo "Principal updated successfully."
else
  # Check if the new principal already exists
  if echo "$CURRENT_POLICY" | grep -q "$NEW_PRINCIPAL"; then
    echo "Principal is already in the new format. No update needed."
  else
    echo "Could not find the old principal format in the policy."
    echo "Adding the new principal binding..."
    gcloud iam service-accounts add-iam-policy-binding "${SA_EMAIL}" \
      --member="${NEW_PRINCIPAL}" \
      --role="roles/iam.workloadIdentityUser"
    
    echo "Principal added successfully."
  fi
fi

echo ""
echo "================================================================"
echo "                      UPDATE COMPLETED                          "
echo "================================================================"
echo ""
echo " IMPORTANT: The Workload Identity Federation Principal has been updated."
echo " If you have any GitHub workflows that use this principal, they might"
echo " need to be updated to match the new format."
echo ""
echo " Name: WORKLOAD_IDENTITY_PROVIDER"
echo " Value: ${POOL_ID}/providers/${PROVIDER_NAME}"
echo ""
echo "================================================================"
