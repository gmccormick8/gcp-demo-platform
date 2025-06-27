# ArgoCD Terraform Module

This module installs and configures ArgoCD on a Kubernetes cluster (GKE), setting up projects and applications from a GitOps repository. It leverages the community-maintained `squareops/argocd/kubernetes` Terraform module.

## Features

- Simplified ArgoCD deployment using the squareops community module
- Configures ArgoCD Projects and Applications 
- Supports custom Ingress configuration
- Manages ArgoCD admin password via Secret Manager integration
- Creates GitOps project structure automatically
- Configures automatic application syncing
- High availability configuration options

## Usage

```hcl
module "argocd" {
  source = "./modules/argocd"
  
  # Password from Secret Manager or explicit setting
  admin_password_secret_id = var.argocd_secret_name
  # or directly set the password (not recommended for production)
  # admin_password = "your-secure-password"
  
  # Environment and repository configuration
  environment = var.environment
  gitops_repo_url = var.gitops_repo_url
  
  # Optional: Enable HA mode for production
  ha_enabled = true
  
  # Optional: Configure ingress
  ingress_enabled = true
  ingress_host = "argocd.example.com"
  ingress_annotations = {
    "kubernetes.io/ingress.class": "gce"
  }
  
  # Create ArgoCD projects
  argocd_projects = {
    default = {
      name        = "default"
      description = "Default Project"
      source_repos = [
        var.gitops_repo_url
      ]
      destinations = [
        {
          server    = "https://kubernetes.default.svc"
          namespace = "*"
        }
      ]
    }
  }
  
  # Create ArgoCD applications
  argocd_applications = {
    demo-app = {
      name           = "demo-app"
      project        = "default"
      repo_url       = var.gitops_repo_url
      target_revision = var.environment
      path           = "charts/demo-app"
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "demo"
      }
      sync_policy = {
        automated = {
          prune      = true
          self_heal  = true
          allow_empty = false
        }
        sync_options = ["CreateNamespace=true"]
      }
      helm_values = {
        raw_values = <<-EOT
          replicaCount: 2
          resources:
            requests:
              memory: "64Mi"
              cpu: "250m"
            limits:
              memory: "128Mi"
              cpu: "500m"
        EOT
      }
    }
  }
}
```

## Requirements

- Kubernetes Cluster (GKE)
- Helm provider
- Kubernetes provider
- Secret Manager access (optional)
- Existing Git repository with Helm charts

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| namespace | Kubernetes namespace for ArgoCD | `string` | `"argocd"` | no |
| admin_password | Admin password for ArgoCD (directly set) | `string` | `""` | no |
| admin_password_secret_id | Secret Manager secret ID with ArgoCD admin password | `string` | `""` | no |
| environment | Environment/branch to deploy from the Git repository | `string` | `"main"` | no |
| gitops_repo_url | URL of the Git repository with ArgoCD configs | `string` | `""` | no |
| argocd_projects | Map of ArgoCD projects to create | `map(object)` | `{}` | no |
| argocd_applications | Map of ArgoCD applications to create | `map(object)` | `{}` | no |
| ingress_enabled | Whether to create an ingress for ArgoCD | `bool` | `false` | no |
| ingress_host | Hostname for ArgoCD ingress | `string` | `"argocd.example.com"` | no |
| server_service_type | Service type for ArgoCD server | `string` | `"ClusterIP"` | no |
| ha_enabled | Enable high availability mode | `bool` | `false` | no |
| server_insecure | Allow insecure connections to the server | `bool` | `true` | no |
| custom_helm_values | Additional custom Helm values | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| argocd_namespace | Namespace where ArgoCD is installed |
| argocd_url | URL to access ArgoCD UI |
| argocd_admin_username | ArgoCD admin username |
| argocd_admin_password | ArgoCD admin password (sensitive) |
| application_names | Names of ArgoCD applications created |
| project_names | Names of ArgoCD projects created |
