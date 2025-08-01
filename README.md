# GCP Infrastructure Demo Platform

This repository demonstrates a secure infrastructure deployment to Google Cloud Platform using Workload Identity Federation with GitHub Actions and Terraform. It includes a multi-cluster GKE setup with ArgoCD for GitOps management.

## Features

- **Multi-Environment Infrastructure**
  - Separate environments for dev, staging, and prod
  - Environment-specific configurations and secrets
  - Secure environment promotion pipeline

- **Security First**
  - Workload Identity Federation for keyless authentication
  - Secret Manager integration for sensitive data
  - Least privilege service accounts
  - Secure ArgoCD password management

- **GitOps Ready**
  - ArgoCD pre-configured for multi-cluster management
  - Secure password management via Secret Manager
  - Automated cluster registration
  - Multi-cluster service discovery enabled

## Prerequisites

- Google Cloud Platform account with billing enabled
- GitHub account with permissions to create repositories
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installed and configured
- [Terraform](https://www.terraform.io/downloads.html) (v1.12.x) installed

## Setup Instructions

1. Clone this repository:
   ```bash
   git clone https://github.com/gmccormick8/gcp-demo-platform.git
   cd gcp-demo-platform
   ```


2. Run the initialization script for each environment (password is required):
   ```bash
   # For production environment with ArgoCD password
   ./init.sh prod SecurePassword123

   # For staging environment with ArgoCD password
   ./init.sh staging MySecurePassword456

   # For development environment with ArgoCD password
   ./init.sh dev DevPassword789
   ```

   The password must be at least 8 characters long.

   This script:
   - Sets up Workload Identity Federation
   - Creates a Terraform service account with least privilege
   - Creates a secure Terraform state bucket with versioning
   - Creates an ArgoCD admin password in Secret Manager (using your provided password)
   - Outputs all necessary GitHub secrets

3. Configure GitHub environments:
   - Create environments for `dev`, `staging`, and `prod`
   - Add the secrets output by the script to each environment:
     - `PROJECT_ID`     - `WORKLOAD_IDENTITY_PROVIDER`
     - `TERRAFORM_SA_EMAIL`
     - `TF_STATE_BUCKET`
     - `ENVIRONMENT` (set to `dev`, `staging`, or `prod` according to the environment)
     - `APPROVERS` (a comma-separated list of GitHub usernames who should be notified for manual approval)
     - `ARGOCD_SECRET_NAME` (name of the Secret Manager secret containing the ArgoCD password)

4. Configure GitHub Environments:
   - Go to your repository settings
   - Create environments for `dev`, `staging`, and `prod`
   - Add the secrets output by the init script to each environment:
     - `PROJECT_ID`
     - `WORKLOAD_IDENTITY_PROVIDER`
     - `SERVICE_ACCOUNT`
     - `TF_STATE_BUCKET`

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       ├── deploy-template.yml        # Deployment workflow template
│       ├── destroy-template.yml       # Infrastructure cleanup workflow template
│       ├── dev-deploy.yml             # Dev deployment workflow
│       ├── dev-destroy.yml            # Dev cleanup workflow
│       ├── enforce-merge-policy.yml   # Force merges to follow Dev => Staging => Prod
│       ├── prod-deploy.yml            # Prod deployment workflow
│       ├── prod-destroy.yml           # Prod cleanup workflow
│       ├── staging-deploy.yml         # Dev deployment workflow
│       └── staging-destroy.yml        # Dev cleanup workflow    
├── modules/
│   ├── argocd/                        # ArgoCD deployment module
│   ├── gke/                           # GKE cluster module
│   └── network/                       # VPC network module
├── .gitignore
├── dev.tfvars                         # Development environment configuration
├── LICENSE
├── README.md
├── init.sh                            # Environment setup script
├── main.tf                            # Main Terraform configuration
├── outputs.tf                         # Output definitions
├── prod.tfvars                        # Production environment configuration
├── providers.tf                       # Provider configuration
├── staging.tfvars                     # Staging environment configuration
└── variables.tf                       # Variable definitions
```

## Security Features

- **Authentication**
  - Workload Identity Federation for keyless authentication
  - Environment-specific service accounts
  - ArgoCD password stored in Secret Manager

- **State Management**
  - Separate state buckets per environment
  - State bucket versioning enabled
  - Lifecycle policies for old versions

- **Access Control**
  - Required manual approvals for prod changes
  - Branch protection rules
  - Least privilege service accounts

## Password Management

ArgoCD passwords are managed securely through Google Cloud Secret Manager:

- One secret per environment (`argocd-admin-password-[env]`)
- Access controlled via IAM
- Password rotation supported
- Audit logging enabled

## Accessing ArgoCD

After deployment:

1. Get the ArgoCD URL from the deployment outputs (GitHub Actions summary)
2. Retrieve the admin password:
   ```bash
   # Replace with your project ID and environment
   gcloud secrets versions access latest \
     --secret="argocd-admin-password-[env]" \
     --project="[project-id]"
   ```
3. Log in with:
   - Username: `admin`
   - Password: Retrieved from Secret Manager

## Contributing

1. Create a feature branch from `dev`
2. Make your changes
3. Submit a PR to `dev`
4. After approval, changes flow: dev → staging → prod

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
- Environment-specific GitOps branches for configuration management
- Intelligent approval process for infrastructure changes (see [Workflow Approvals](docs/workflow-approvals.md))

## Deploying ArgoCD

ArgoCD is deployed automatically across all clusters during the Terraform apply process. The admin password is managed securely through Google Cloud Secret Manager and is unique for each environment (dev/staging/prod).

The password is:
- Generated during initial setup by the `init.sh` script
- Stored in Secret Manager as `argocd-admin-password-[env]`
- Retrieved automatically by the ArgoCD module during deployment
- Never exposed in Terraform configuration or state files

To deploy ArgoCD and the entire infrastructure:

1. Initialize Terraform:
   ```bash
   terraform init -backend-config="bucket=$TF_STATE_BUCKET"
   ```

2. Review the changes:
   ```bash
   terraform plan
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```

The deployment process is automated through GitHub Actions workflows in the `.github/workflows/deploy.yml` file, which handles environment-specific deployments when changes are pushed to the corresponding branches (dev/staging/prod).

## Contributing

1. Create a feature branch
2. Make your changes
3. Submit a pull request

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.