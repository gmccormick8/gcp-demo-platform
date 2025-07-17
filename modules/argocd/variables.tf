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

variable "region" {
  description = "The GCP region where resources will be created"
  type        = string
}

# Hub/Spoke topology: set true for central (hub) cluster, false for spokes
variable "is_hub" {
  description = "Whether this ArgoCD instance is the hub (true) or a spoke (false)"
  type        = bool
  default     = false
}

# GCP project ID
variable "project_id" {
  description = "GCP project ID for Workload Identity Federation"
  type        = string
}

# GCP Service Account name for ArgoCD (Workload Identity)
variable "gcp_sa_name" {
  description = "GCP Service Account name for ArgoCD Workload Identity"
  type        = string
  default     = "argocd-wi"
}

# Kubernetes Service Account name for ArgoCD
variable "k8s_sa_name" {
  description = "Kubernetes Service Account name for ArgoCD"
  type        = string
  default     = "argocd-wi"
}
