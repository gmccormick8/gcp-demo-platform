# ArgoCD Module

This module deploys and configures ArgoCD in a GKE cluster with secure authentication using Google Cloud Secret Manager.

## Features

- **Secure Password Management**
  - Admin password stored in Google Secret Manager
  - Environment-specific secrets (dev/staging/prod)
  - Automatic secret mounting in ArgoCD
  - Workload Identity integration for secure access

- **Multi-Cluster Configuration**
  - Automatic registration of east, west, and central clusters
  - Secure cluster credentials management
  - Cross-cluster service discovery ready

- **Security**
  - Workload Identity Federation integration
  - Least privilege service account permissions
  - Secure secret access configuration

## Usage

Basic usage:

```hcl
module "argocd" {
  source = "./modules/argocd"
  
  project_id   = var.project_id
  environment  = "dev"
  namespace    = "argocd"
  gcp_sa_name  = "argocd-sa"
  k8s_sa_name  = "argocd-k8s-sa"
}
```

## Requirements

- Google Cloud Secret Manager API enabled
- GKE cluster with Workload Identity enabled
- ArgoCD admin password stored in Secret Manager
- Service account with Secret Manager access

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| project_id | GCP Project ID | string | yes |
| environment | Deployment environment (dev/staging/prod) | string | yes |
| namespace | Kubernetes namespace for ArgoCD | string | yes |
| gcp_sa_name | Name for the GCP service account | string | yes |
| k8s_sa_name | Name for the Kubernetes service account | string | yes |
| gitops_repo_url | URL of the GitOps repository | string | no |

## Password Management

The module expects the ArgoCD admin password to be stored in Secret Manager with the following naming convention:
- Secret name: `argocd-admin-password-[environment]`
- Example: `argocd-admin-password-dev` for the dev environment

The password can be managed using the following methods:
1. Initial setup via the `init.sh` script
2. Manual rotation through Secret Manager
3. Automated rotation using Secret Manager features (if implemented)

## Outputs

| Name | Description |
|------|-------------|
| argocd_release | Information about the ArgoCD Helm release |

## Notes

- The password is stored as plaintext in Secret Manager and hashed by ArgoCD internally
- Service account permissions are configured with least privilege
- Secret access is restricted to the ArgoCD service account
