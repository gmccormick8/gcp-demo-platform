variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod) - used for GitOps branch targeting"
  type        = string
  default     = "dev"
}

variable "gitops_repo_url" {
  description = "URL of the Git repository containing ArgoCD configuration"
  type        = string
  default     = "https://github.com/gmccormick8/gcp-demo-app.git"
}
