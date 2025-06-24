variable "control_cluster" {
  description = "Indicates if the cluster is a control cluster"
  type        = bool
  default     = false
}

variable "admin_password_secret_name" {
  description = "Name of the GCP Secret Manager secret containing the plaintext ArgoCD admin password"
  type        = string

  validation {
    condition     = var.admin_password_secret_name != ""
    error_message = "The admin_password_secret_name is required and must be a valid Secret Manager secret name."
  }
}

variable "project_id" {
  description = "The GCP project ID where secrets are stored"
  type        = string
  default     = ""
}

variable "enable_sso" {
  description = "Enable SSO integration with Dex"
  type        = bool
  default     = false
}

variable "dex_config" {
  description = "Dex connector configuration for SSO"
  type        = string
  default     = ""
}

variable "argocd_url" {
  description = "External URL for ArgoCD (optional)"
  type        = string
  default     = ""
}

variable "gitops_repo_url" {
  description = "Git repository URL containing the application manifests"
  type        = string
  default     = "https://github.com/gmccormick8/gcp-demo-platform-configs.git"
}

variable "gitops_repo_branch" {
  description = "Git branch to use for GitOps (usually matches the deployment environment: dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "remote_clusters" {
  description = "List of remote clusters to register with ArgoCD"
  type = list(object({
    name           = string
    endpoint       = string
    token          = string
    ca_certificate = string
    provider_alias = string
  }))
  default = []
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster where ArgoCD is deployed"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint of the Kubernetes cluster"
  type        = string
}

variable "cluster_ca_cert" {
  description = "CA certificate of the Kubernetes cluster"
  type        = string
}
