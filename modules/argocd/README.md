# ArgoCD Terraform Module

This module deploys ArgoCD to a Kubernetes cluster to enable GitOps-based continuous delivery for your applications.

## Features

- Highly available ArgoCD deployment for production environments
- Automatic registration of remote clusters
- Support for ApplicationSet controller for multi-cluster deployments
- SSO integration capability
- Predefined sensible defaults

## Usage

### Basic Example

```hcl
module "argocd" {
  source           = "./modules/argocd"
  cluster_name     = module.gke_clusters["central"].cluster_name
  cluster_endpoint = module.gke_clusters["central"].cluster_endpoint
  cluster_ca_cert  = module.gke_clusters["central"].master_auth.cluster_ca_certificate
  control_cluster  = true
}
```

### Advanced Example with Remote Clusters

```hcl
module "argocd" {
  source           = "./modules/argocd"
  cluster_name     = module.gke_clusters["central"].cluster_name
  cluster_endpoint = module.gke_clusters["central"].cluster_endpoint
  cluster_ca_cert  = module.gke_clusters["central"].master_auth.cluster_ca_certificate
  control_cluster  = true
  # Use Secret Manager for the ArgoCD admin password
  project_id = var.project_id
  admin_password_secret_name = "argocd-admin-password"
  
  # Alternatively, provide a bcrypt hash directly (less secure)
  # admin_password_hash = var.argocd_admin_password
  
  # No external URL needed - we're using kubectl port-forward for access
  
  # Git repository for application configuration
  gitops_repo_url = "https://github.com/example/gitops-config.git"
  
  # Register remote clusters
  remote_clusters = [
    {
      name           = "east-cluster"
      endpoint       = "https://cluster-endpoint-east"
      token          = "service-account-token"
      ca_certificate = "cluster-ca-certificate"
    },
    {
      name           = "west-cluster"
      endpoint       = "https://cluster-endpoint-west"
      token          = "service-account-token"
      ca_certificate = "cluster-ca-certificate"
    }
  ]
}
```

## Requirements

- Kubernetes cluster with RBAC enabled
- Helm provider configured
- Kubernetes provider configured

## Accessing ArgoCD

This module is designed to work without a domain name or ingress controller. To access the ArgoCD UI:

1. Set up kubectl to access your GKE cluster (using gcloud)
   ```bash
   gcloud container clusters get-credentials central-cluster --zone us-central1-c --project your-project-id
   ```

2. Set up port-forwarding to the ArgoCD server
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```

3. Open your browser and navigate to https://localhost:8080

4. Accept the self-signed certificate warning

5. Login with:
   - Username: admin
   - Password: Retrieve from Secret Manager with the command:
     ```bash
     gcloud secrets versions access latest --secret=argocd-admin-password --project=your-project-id
     ```

The module provides these instructions as an output value for easy reference.

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| control_cluster | Whether this is the control cluster for ArgoCD | `bool` | `false` | no |
| cluster_name | Name of the Kubernetes cluster | `string` | n/a | yes |
| cluster_endpoint | Endpoint of the Kubernetes cluster | `string` | n/a | yes |
| cluster_ca_cert | CA certificate of the Kubernetes cluster | `string` | n/a | yes |
| admin_password_secret_name | Name of the GCP Secret Manager secret containing the ArgoCD admin password | `string` | n/a | yes |
| enable_sso | Enable SSO integration | `bool` | `false` | no |
| dex_config | Dex connector configuration for SSO | `string` | `""` | no |
| argocd_url | External URL for ArgoCD | `string` | `""` | no |
| gitops_repo_url | Git repository URL for application manifests | `string` | `"https://github.com/gmccormick8/gcp-demo-platform-configs.git"` | no |
| remote_clusters | List of remote clusters to register with ArgoCD | `list(object({...}))` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| argocd_namespace | Namespace where ArgoCD is deployed |
| argocd_server_service | Name of the ArgoCD server service |
| argocd_server_admin_password | Initial admin password for ArgoCD server |

## Notes

1. For production deployments, make sure to:
   - Set a custom admin password
   - Configure a proper external URL
   - Use a private Git repository with proper authentication
   - Consider enabling SSO

2. The default admin password is 'argocd123' if no custom password hash is provided.

3. Remote clusters are registered automatically when `control_cluster = true` and the `remote_clusters` list is provided.
