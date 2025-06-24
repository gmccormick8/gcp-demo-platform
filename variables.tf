variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "argocd_secret_name" {
  description = "Name of the Secret Manager secret containing the plaintext ArgoCD admin password"
  type        = string
  validation {
    condition     = length(var.argocd_secret_name) > 0
    error_message = "The argocd_secret_name variable must be set to a valid Secret Manager secret name."
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod) - used for GitOps branch targeting"
  type        = string
  default     = "dev"
}

variable "gitops_repo_url" {
  description = "URL of the Git repository containing ArgoCD configuration"
  type        = string
  default     = "https://github.com/gmccormick8/gcp-demo-platform-app.git"
}

variable "master_authorized_networks" {
  description = "List of CIDR blocks that are allowed to access the master's API endpoint"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "All IPs - For GitHub Actions"
    }
  ]
}
