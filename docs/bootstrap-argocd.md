# Bootstrapping ArgoCD with Secret Manager

This document explains how to bootstrap your environment with ArgoCD using Google Secret Manager for password management.

## Bootstrapping Process

When bootstrapping a new environment, you need to ensure the ArgoCD admin password is securely managed. The recommended approach is:

1. **Pre-create the password secret** - Before running Terraform, create the secret in Google Secret Manager
2. **Run Terraform to deploy infrastructure** - Terraform will use the existing secret
3. **Deploy applications with ArgoCD** - Use the secure password to access ArgoCD

## Bootstrap Steps

### 1. Set Up the Secret

Run the provided bootstrap script:

```bash
# Make the script executable
chmod +x ./scripts/bootstrap-argocd-password.sh

# Run with your project ID and optional custom password
./scripts/bootstrap-argocd-password.sh your-gcp-project-id YourSecureP@ssw0rd
```

This script:
- Generates a bcrypt hash of your password
- Creates a secret in Google Secret Manager
- Sets appropriate permissions

### 2. Run Terraform

Initialize and apply your Terraform configuration:

```bash
terraform init
terraform apply
```

The `argocd` module will retrieve the password hash from Secret Manager.

### 3. Handle Secret Not Found Cases

The module includes a fallback mechanism:

- If the secret does not exist, it falls back to `admin_password_hash` if provided 
- If neither is available, it uses the default password 'argocd123'

This ensures your deployment succeeds even in bootstrap scenarios.

## GitHub Actions Integration

In your GitHub Actions workflow:

1. The workflow authenticates to GCP using Workload Identity Federation
2. This provides secure access to Secret Manager
3. Terraform runs and retrieves the secret during deployment

No modification to your GitHub Actions workflow is needed as long as the service account has Secret Manager access.

## Secret Management Lifecycle

1. **Bootstrap Phase**: Create secret manually using the script
2. **Deployment Phase**: Terraform accesses the existing secret
3. **Maintenance Phase**: Rotate the secret without changing Terraform code

## Troubleshooting

If you encounter issues during bootstrap:

1. Check the secret exists: `gcloud secrets describe argocd-admin-password --project=YOUR_PROJECT_ID`
2. Verify permissions: `gcloud secrets get-iam-policy argocd-admin-password --project=YOUR_PROJECT_ID`
3. Manual fallback: Set `admin_password_hash` directly in your Terraform variables
