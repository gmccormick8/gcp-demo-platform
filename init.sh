#!/bin/bash
# This script sets up the GCP environment for GitHub Actions integration using Workload Identity Federation.
# It configures the complete bootstrap environment including:
#   - API enablement
#   - Workload Identity Federation
#   - Least privilege IAM roles
#   - Terraform state storage
#   - ArgoCD admin password in Secret Manager
# 
# Requirements:
#   - GCloud CLI installed and initialized
#   - Valid GCP project with billing enabled
#   - Project Owner or Editor permissions
#
# Usage: ./init.sh <branch> <argocd-password>
#   - branch: dev, staging, or prod
#   - argocd-password: Required password for ArgoCD (must be at least 8 characters)

# Exit immediately if a command exits with a non-zero status.
set -e

echo "==============================================================="
echo "    Setting up GCP environment for CI/CD with ArgoCD           "
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
  echo "Usage: ./init.sh <branch> <argocd-password>"
  exit 1
fi

BRANCH="$1"
if [[ ! "$BRANCH" =~ ^(dev|staging|prod)$ ]]; then
  echo "Error: Branch must be 'dev', 'staging', or 'prod'"
  exit 1
fi

# Check for the required ArgoCD password parameter
if [ -z "$2" ]; then
  echo "Error: ArgoCD password parameter is required"
  echo "Usage: ./init.sh <branch> <argocd-password>"
  exit 1
fi

# Validate that the password is at least 8 characters long
ARGOCD_PASSWORD="$2"
if [ ${#ARGOCD_PASSWORD} -lt 8 ]; then
  echo "Error: ArgoCD password must be at least 8 characters long"
  exit 1
fi

# Main script logic
echo "Step 1/5: Enabling required APIs..."
api_array=(
  "secretmanager.googleapis.com"
  "compute.googleapis.com"
  "iam.googleapis.com"
  "iamcredentials.googleapis.com"
  "cloudresourcemanager.googleapis.com"
  "storage.googleapis.com"
  "container.googleapis.com"
  "gkehub.googleapis.com"
  "anthos.googleapis.com"
  "serviceusage.googleapis.com"
  "multiclusteringress.googleapis.com"
  "multiclusterservicediscovery.googleapis.com"
)

for api in "${api_array[@]}"; do
  echo "Enabling API: $api"
  gcloud services enable "$api" --project="$PROJECT_ID"
done

# Set variables
random_number=$((RANDOM % 99999 + 0))
POOL_NAME="${BRANCH}-github-pool-${random_number}"
PROVIDER_NAME="github"
REPO="gmccormick8/gcp-demo-platform"

# Get Project number
PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" --format="value(projectNumber)")

# Create Workload Identity Pool
echo "Step 2/5: Setting up Workload Identity Federation..."
echo "Creating Workload Identity Pool..."
gcloud iam workload-identity-pools create "${POOL_NAME}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="GitHub Actions Pool - ${BRANCH}" \
  --description="Workload Identity Pool for GitHub Actions - ${BRANCH} environment"

# Wait for the pool to be created
sleep 10

# Get the Workload Identity Pool ID
POOL_ID=$(gcloud iam workload-identity-pools describe "${POOL_NAME}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --format="value(name)")

# Create Workload Identity Provider with enhanced security
echo "Creating Workload Identity Provider..."
gcloud iam workload-identity-pools providers create-oidc "${PROVIDER_NAME}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="${POOL_NAME}" \
  --display-name="GitHub Provider - ${BRANCH}" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository_id=assertion.repository_id,attribute.workflow_ref=assertion.workflow_ref,attribute.actor_id=assertion.actor_id" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-condition="assertion.repository_id == '999072242' && (assertion.workflow_ref == 'gmccormick8/gcp-demo-platform/.github/workflows/deploy.yml@refs/heads/${BRANCH}' || assertion.workflow_ref == 'gmccormick8/gcp-demo-platform/.github/workflows/destroy.yml@refs/heads/${BRANCH}') && assertion.actor_id == '74574750'" \

# Define the Workload Identity principal for the specific repo and branch
WI_PRINCIPAL="principalSet://iam.googleapis.com/${POOL_ID}/attribute.repository_id/999072242"

# Grant necessary roles using least privilege principle
echo "Step 3/5: Applying least privilege IAM policies..."

# Create a custom service account for Terraform operations
SA_NAME="tf-${BRANCH}-sa"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "Creating Terraform service account..."
gcloud iam service-accounts create "$SA_NAME" \
  --project="${PROJECT_ID}" \
  --description="Service account for Terraform operations in the ${BRANCH} environment" \
  --display-name="Terraform ${BRANCH} SA"

# Allow the Workload Identity principal to impersonate the service account
gcloud iam service-accounts add-iam-policy-binding "${SA_EMAIL}" \
  --project="${PROJECT_ID}" \
  --member="${WI_PRINCIPAL}" \
  --role="roles/iam.workloadIdentityUser"

# Allow the Workload Identity principal to create tokens for the service account
gcloud iam service-accounts add-iam-policy-binding "${SA_EMAIL}" \
  --project="${PROJECT_ID}" \
  --member="${WI_PRINCIPAL}" \
  --role="roles/iam.serviceAccountTokenCreator"

# Grant the service account the necessary roles for Terraform operations
ROLES=(
  # Basic service usage and viewing
  "roles/viewer"                     # Base viewer role
  "roles/serviceusage.serviceUsageConsumer"  # Allow using enabled services
  
  # Storage for Terraform state
  "roles/storage.admin"              # Manage Terraform state buckets
  
  # Compute and networking
  "roles/compute.networkAdmin"       # Manage VPC networks and subnets
  "roles/compute.securityAdmin"      # Manage firewall rules
  
  # IAM management
  "roles/iam.serviceAccountAdmin"    # Manage service accounts
  "roles/iam.serviceAccountUser"     # Use service accounts
  "roles/resourcemanager.projectIamAdmin"  # Manage IAM permissions
  
  # GKE management
  "roles/container.admin"            # Manage GKE clusters
  "roles/container.clusterAdmin"     # Admin GKE clusters
  
  # Multi-cluster management
  "roles/gkehub.admin"               # Manage GKE Hub
  
  # Secret management
  "roles/secretmanager.admin"        # For managing secrets
)

# Apply the roles to the service account
for role in "${ROLES[@]}"; do
  echo "Granting $role to $SA_EMAIL..."
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="$role" 
done

# Create Terraform state bucket with enhanced security
BUCKET_NAME="${BRANCH}-tf-state-${PROJECT_ID}"
echo "Step 4/5: Creating secure Terraform state bucket..."
gcloud storage buckets create gs://${BUCKET_NAME} \
  --project=${PROJECT_ID} \
  --location=us \
  --public-access-prevention \
  --uniform-bucket-level-access

sleep 5

echo "Enabling versioning and lifecycle rules for Terraform state..."
gcloud storage buckets update gs://${BUCKET_NAME} --versioning

# Add lifecycle policy
cat > /tmp/lifecycle-config.json << EOL
{
  "lifecycle": {
    "rule": [
      {
        "action": {
          "type": "Delete"
        },
        "condition": {
          "numNewerVersions": 5,
          "isLive": false
        }
      }
    ]
  }
}
EOL

gcloud storage buckets update gs://${BUCKET_NAME} --lifecycle-file=/tmp/lifecycle-config.json
rm /tmp/lifecycle-config.json

# Set up ArgoCD admin password in Secret Manager
echo "Step 5/5: Setting up ArgoCD admin password in Secret Manager..."

# Create ArgoCD admin password in Secret Manager
echo "Creating ArgoCD admin password in Secret Manager..."
SECRET_NAME="argocd-admin-password-${BRANCH}"
echo -n "$ARGOCD_PASSWORD" | gcloud secrets create "$SECRET_NAME" \
  --replication-policy="automatic" \
  --data-file=- \
  --project="$PROJECT_ID"

echo "Note: Password stored as plaintext in Secret Manager. ArgoCD will hash it internally."

# Grant access to the Terraform service account
echo "Granting access to Terraform service account..."
gcloud secrets add-iam-policy-binding "$SECRET_NAME" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/secretmanager.secretAccessor" \
  --project="$PROJECT_ID"

# Output important information
echo ""
echo "================================================================"
echo "                   SETUP COMPLETED SUCCESSFULLY                 "
echo "================================================================"
echo ""
echo " IMPORTANT: Use the below to create GitHub Environment Secrets:"
echo ""
echo " Name: PROJECT_ID"
echo " Value: ${PROJECT_ID}"
echo ""
echo " Name: WORKLOAD_IDENTITY_PROVIDER"
echo " Value: ${POOL_ID}/providers/${PROVIDER_NAME}"
echo ""
echo " Name: TERRAFORM_SA_EMAIL"
echo " Value: ${SA_EMAIL}"
echo ""
echo " Name: TF_STATE_BUCKET"
echo " Value: ${BUCKET_NAME}"
echo ""
echo " Name: ARGOCD_SECRET_NAME"
echo " Value: ${SECRET_NAME}"
echo ""
echo " Name: ARGOCD_ADMIN_PASSWORD"
echo " Value: ${ARGOCD_PASSWORD}"
echo ""
echo "================================================================"
echo ""
echo " Store these values securely - especially the ArgoCD password!"
echo " Update your terraform configuration to use these values."
echo ""
echo "================================================================"