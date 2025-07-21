variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod) - used for GitOps branch targeting"
  type        = string
  default     = "dev"
}

