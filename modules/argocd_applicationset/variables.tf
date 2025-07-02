variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "argocd_namespace" {
  description = "The namespace where ArgoCD is installed"
  type        = string
}

variable "clusters" {
  description = "Map of cluster endpoints"
  type        = map(string)
}

variable "application_name" {
  description = "Name of the application to deploy"
  type        = string
}

variable "repo_url" {
  description = "Git repository URL containing the application manifests"
  type        = string
}

variable "target_revision" {
  description = "Git branch or tag to deploy"
  type        = string
}

variable "path" {
  description = "Path within the repository to the application manifests"
  type        = string
}
