variable "cluster_endpoint" {
  description = "The endpoint of the Kubernetes cluster"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "The cluster CA certificate"
  type        = string
}

variable "access_token" {
  description = "The access token for the Kubernetes cluster"
  type        = string
}

variable "namespace" {
  description = "The namespace to install ArgoCD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "The version of the ArgoCD Helm chart"
  type        = string
  default     = "5.28.0"
}

variable "gitops_repo_url" {
  description = "URL of the Git repository containing Helm chart configurations"
  type        = string
  default     = "https://github.com/gmccormick8/gcp-demo-app.git"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}
