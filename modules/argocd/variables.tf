variable "namespace" {
  description = "The Kubernetes namespace where ArgoCD will be installed"
  type        = string
  default     = "argocd"
}

variable "server_service_type" {
  description = "Kubernetes service type for ArgoCD server"
  type        = string
  default     = "ClusterIP"
}

variable "admin_password" {
  description = "The admin password for ArgoCD. If not specified, will use the password from Secret Manager if admin_password_secret_id is set"
  type        = string
  default     = ""
  sensitive   = true
}

variable "admin_password_secret_id" {
  description = "The ID of the Secret Manager secret containing the plain text ArgoCD admin password"
  type        = string
  default     = ""
}

variable "ingress_enabled" {
  description = "Whether to enable Kubernetes ingress for ArgoCD"
  type        = bool
  default     = false
}

variable "ingress_host" {
  description = "Hostname for ArgoCD ingress when enabled"
  type        = string
  default     = "argocd.example.com"
}

variable "ingress_annotations" {
  description = "Map of annotations for ArgoCD ingress"
  type        = map(string)
  default     = {}
}

variable "ingress_tls" {
  description = "TLS configuration for ArgoCD ingress"
  type = list(object({
    hosts      = list(string)
    secretName = string
  }))
  default = []
}

variable "ha_enabled" {
  description = "Whether to enable high availability mode for ArgoCD"
  type        = bool
  default     = false
}

variable "server_insecure" {
  description = "Whether to allow insecure connections to ArgoCD server"
  type        = bool
  default     = true
}

variable "argocd_projects" {
  description = "Map of ArgoCD projects to create"
  type = map(object({
    name         = string
    description  = string
    source_repos = list(string)
    destinations = list(object({
      server    = string
      namespace = string
    }))
  }))
  default = {}
}

variable "argocd_applications" {
  description = "Map of ArgoCD applications to create"
  type = map(object({
    name            = string
    project         = string
    repo_url        = string
    target_revision = string
    path            = string
    destination = object({
      server    = string
      namespace = string
    })
    sync_policy = optional(object({
      automated = object({
        prune       = bool
        self_heal   = bool
        allow_empty = bool
      })
      sync_options = list(string)
    }))
    helm_values = optional(object({
      value_files = optional(list(string))
      parameters = optional(list(object({
        name  = string
        value = string
      })))
      raw_values = optional(string)
    }))
  }))
  default = {}
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod) - used for GitOps branch targeting"
  type        = string
  default     = "main"
}

variable "gitops_repo_url" {
  description = "URL of the Git repository containing application configurations"
  type        = string
  default     = ""
}

variable "custom_helm_values" {
  description = "Custom Helm values to be merged with the module's values"
  type        = string
  default     = ""
}
