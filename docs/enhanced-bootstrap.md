# Enhanced Bootstrap Process

This document explains the enhanced bootstrap process for the GCP Demo Platform with ArgoCD integration.

## Overview

The bootstrap process is now consolidated into a single `init.sh` script that follows security best practices and the principle of least privilege. The script performs:

1. **API Enablement** - Enables only the required GCP APIs
2. **Workload Identity Federation** - Sets up secure authentication for GitHub Actions
3. **Service Account Creation** - Creates a dedicated service account with minimal permissions
4. **Terraform State Storage** - Creates a secure state bucket with versioning and lifecycle policies
5. **ArgoCD Password Management** - Creates a secure password and stores it in Secret Manager

## Security Improvements

### Least Privilege Implementation

The script now creates a dedicated service account for Terraform operations instead of granting broad permissions directly to the Workload Identity Federation principal. This:

1. Follows the principle of least privilege
2. Makes permission management easier
3. Provides better audit trails
4. Allows fine-grained permission controls

### Enhanced Workload Identity Configuration

The Workload Identity Provider now has:

1. More granular attribute mappings
2. Stricter attribute conditions
3. Defined allowed audiences
4. Better environment isolation

### ArgoCD Password Security

ArgoCD passwords are now:

1. Environment-specific (dev/staging/prod)
2. Either user-provided or automatically generated
3. Stored securely in Secret Manager
4. Accessible only to the Terraform service account
5. Labeled for better management

## GitHub Actions Integration

The sample GitHub Actions workflow now:

1. Uses the dedicated service account via Workload Identity Federation
2. Passes the environment-specific secret name to Terraform
3. Never exposes the ArgoCD password in logs or GitHub secrets

## Usage

### Environment Setup

To set up a new environment:

```bash
# Syntax: ./init.sh <environment> [argocd-password]
./init.sh dev  # Auto-generated password
./init.sh prod MySecurePassword  # Custom password
```

### GitHub Secrets

After running the script, set these secrets in your GitHub environment:

1. `PROJECT_ID` - Your GCP project ID
2. `WORKLOAD_IDENTITY_PROVIDER` - The Workload Identity provider path
3. `TERRAFORM_SA_EMAIL` - Email of the Terraform service account
4. `TF_STATE_BUCKET` - Name of the Terraform state bucket
5. `ARGOCD_SECRET_NAME` - Name of the Secret Manager secret for ArgoCD password
6. `ARGOCD_ADMIN_PASSWORD` - The generated or provided ArgoCD password

### Terraform Configuration

Your Terraform variables now include:

```hcl
variable "argocd_secret_name" {
  description = "Name of the Secret Manager secret for ArgoCD password"
  type        = string
}
```

This is used in the ArgoCD module:

```hcl
module "argocd" {
  source                     = "./modules/argocd"
  admin_password_secret_name = var.argocd_secret_name
}
```
