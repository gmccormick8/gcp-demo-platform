variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "cluster_endpoint" {
  description = "The endpoint of the cluster where ArgoCD will be deployed"
  type        = string
}

variable "cluster_ca_cert" {
  description = "The cluster CA certificate"
  type        = string
}

variable "access_token" {
  description = "Access token for Kubernetes provider"
  type        = string
}

variable "cluster_name" {
  description = "The name of the cluster where ArgoCD will be deployed"
  type        = string
}

variable "argocd_namespace" {
  description = "The namespace where ArgoCD will be installed"
  type        = string
  default     = "argocd"
}

variable "argocd_helm_repo" {
  description = "The Helm repository for ArgoCD"
  type        = string
}

variable "argocd_helm_chart" {
  description = "The Helm chart name for ArgoCD"
  type        = string
}

variable "argocd_version" {
  description = "The version of the ArgoCD Helm chart"
  type        = string
}

variable "argocd_values" {
  description = "Custom values for the ArgoCD Helm chart"
  type        = map(any)
  default     = {}
}
