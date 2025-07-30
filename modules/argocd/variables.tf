variable "project_id" {
  description = "GCP project ID for Workload Identity Federation"
  type        = string
}

variable "gcp_sa_name" {
  description = "GCP Service Account name for ArgoCD"
  type        = string
}

variable "k8s_sa_name" {
  description = "Kubernetes Service Account name for ArgoCD"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace where ArgoCD will be installed"
  type        = string
}

variable "environment" {
  description = "The environment for which the ArgoCD module is being configured"
  type        = string
  default     = "dev"
}

variable "gitops_repo_url" {
  description = "URL of the Git repository containing ArgoCD configuration"
  type        = string
  default     = "https://github.com/gmccormick8/gcp-demo-app.git"
}

variable "clusters" {
  type = map(object({
    endpoint       = string
    ca_certificate = string
    access_token   = string
  }))


  validation {
    condition     = contains(keys(var.clusters), "central")
    error_message = "The clusters map must include a 'central' cluster."
  }
}