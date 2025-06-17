# GCP Infrastructure Demo Platform

This repository demonstrates a secure infrastructure deployment to Google Cloud Platform using Workload Identity Federation with GitHub Actions and Terraform.

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

2. Make the initialization script executable:
   ```bash
   chmod +x init.sh
   ```

3. Run the improved initialization script for each environment:
   ```bash
   # For production environment with custom ArgoCD password
   ./init.sh prod SecurePassword123

   # For staging environment with auto-generated password
   ./init.sh staging

   # For development environment with auto-generated password
   ./init.sh dev
   ```

   This single script now:
   - Sets up Workload Identity Federation
   - Creates a Terraform service account with least privilege
   - Creates a secure Terraform state bucket with versioning
   - Creates an ArgoCD admin password in Secret Manager
   - Outputs all necessary GitHub secrets

4. Configure GitHub environments:
   - Create environments for `dev`, `staging`, and `prod`
   - Add the secrets output by the script to each environment:
     - `PROJECT_ID`
     - `WORKLOAD_IDENTITY_PROVIDER`
     - `TERRAFORM_SA_EMAIL`
     - `TF_STATE_BUCKET`
     - `ENVIRONMENT` (set to `dev`, `staging`, or `prod` according to the environment)
     - `APPROVERS` (a comma-separated list of GitHub usernames who should be notified for manual approval)
     - `ARGOCD_SECRET_NAME`
     - `ARGOCD_ADMIN_PASSWORD` (consider storing this in a password manager instead)

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
│       └── deploy.yml      # GitHub Actions workflow
├── .gitignore
├── LICENSE
├── README.md
├── init.sh                # Environment setup script
├── main.tf               # Main Terraform configuration
├── providers.tf          # Provider configuration
└── variables.tf         # Variable definitions
```

## Security Features

- Workload Identity Federation for keyless authentication
- Environment-specific service accounts
- State bucket versioning enabled
- Branch protection rules recommended
- Separate environments with isolated state storage
- Environment-specific GitOps branches for configuration management
- Intelligent approval process for infrastructure changes (see [Workflow Approvals](docs/workflow-approvals.md))

## Contributing

1. Create a feature branch
2. Make your changes
3. Submit a pull request

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.