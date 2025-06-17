variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "argocd_secret_name" {
  description = "Name of the Secret Manager secret containing the ArgoCD admin password hash"
  type        = string
  default     = "argocd-admin-password" # Will be overridden by tfvars or environment variables
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod) - used for GitOps branch targeting"
  type        = string
  default     = "dev"
}
