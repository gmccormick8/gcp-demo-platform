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

3. Run the initialization script for each environment (password is required):
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

4. Configure GitHub environments:
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
- Secure storage of ArgoCD admin password in Secret Manager
- Required explicit password setting during initialization

## Accessing ArgoCD After Deployment

After a successful deployment, you can access ArgoCD using the following steps:

1. Get the ArgoCD URL from the deployment outputs (shown in GitHub Actions summary)
2. Retrieve the admin password from Secret Manager:
   ```bash
   gcloud secrets versions access latest --secret=argocd-admin-password --project=YOUR_PROJECT_ID
   ```
3. Log in with username `admin` and the password retrieved from Secret Manager
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