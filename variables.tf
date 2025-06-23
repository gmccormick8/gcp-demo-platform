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

variable "master_authorized_networks" {
  description = "List of CIDR blocks that are allowed to access the master's API endpoint"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [
    {
      cidr_block   = "0.0.0.0/0" # Allow all IPs for demonstration - restrict this in production!
      display_name = "All IPs - For GitHub Actions"
    }
  ]
}
