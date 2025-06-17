# Setting Up ArgoCD Admin Password with Google Secret Manager

This guide explains how to securely manage the ArgoCD admin password using Google Secret Manager for your CI/CD pipeline with GitHub Actions.

## Prerequisites

- Google Cloud project with Secret Manager API enabled
- Appropriate IAM permissions to create and access secrets
- GitHub repository configured with Google Workload Identity Federation

## Steps to Configure the Password

### 1. Generate a Secure Password Hash

ArgoCD stores passwords as bcrypt hashes. Generate a hash for your password:

```bash
# Install htpasswd utility if needed
sudo apt-get update && sudo apt-get install -y apache2-utils

# Generate bcrypt hash (replace 'your-secure-password' with your desired password)
htpasswd -bnBC 10 "" your-secure-password | tr -d ':\n' | sed 's/$2y/$2a/'
```

The command will output something like: `$2a$10$dryiLlwrSLZgcH4tzft2OO6pMrPsv6mcl1VHJCMTbJ6W1dpjVrFJC`

### 2. Create a Secret in Google Secret Manager

```bash
# Create the secret
gcloud secrets create argocd-admin-password --project=YOUR_PROJECT_ID

# Add the password hash to the secret
echo -n "$2a$10$dryiLlwrSLZgcH4tzft2OO6pMrPsv6mcl1VHJCMTbJ6W1dpjVrFJC" | \
  gcloud secrets versions add argocd-admin-password --data-file=- --project=YOUR_PROJECT_ID
```

### 3. Grant Access to GitHub Actions Identity

```bash
# Get the GitHub Actions service account
SERVICE_ACCOUNT="$(gcloud iam service-accounts list --filter="email~github-actions" --format="value(email)" --project=YOUR_PROJECT_ID)"

# Grant Secret Manager Secret Accessor role
gcloud secrets add-iam-policy-binding argocd-admin-password \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor" \
  --project=YOUR_PROJECT_ID
```

### 4. Configure Terraform Module

In your terraform configuration:

```hcl
module "argocd" {
  source                   = "./modules/argocd"
  # ...other configuration...
  project_id               = var.project_id
  admin_password_secret_name = "argocd-admin-password"
}
```

## Security Notes

1. The password hash is never exposed in your GitHub Actions workflow
2. Secret Manager handles secure storage and access control
3. Workload Identity Federation avoids the need for long-lived service account keys
4. The secret is only accessed during the terraform apply phase

## Rotating the Password

To rotate the ArgoCD admin password:

1. Generate a new bcrypt hash as shown above
2. Add a new version of the secret:

```bash
echo -n "NEW_PASSWORD_HASH" | \
  gcloud secrets versions add argocd-admin-password --data-file=- --project=YOUR_PROJECT_ID
```

3. Run the Terraform pipeline to update the deployment
4. The new password will take effect after ArgoCD restarts
