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

variable "app_namespace" {
  description = "Namespace for ArgoCD applications"
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

variable "central_cluster_endpoint" {
  description = "The endpoint of the central Kubernetes cluster to register with ArgoCD"
  type        = string
}

variable "central_cluster_ca_certificate" {
  description = "The cluster CA certificate"
  type        = string
}

variable "central_access_token" {
  description = "The access token for the Kubernetes cluster"
  type        = string
}

variable "central_region" {
  description = "The GCP region where resources will be created"
  type        = string
}

variable "east_cluster_endpoint" {
  description = "The endpoint of the east Kubernetes cluster to register with ArgoCD"
  type        = string
}

variable "east_cluster_ca_certificate" {
  description = "The CA certificate of the east Kubernetes cluster"
  type        = string
}

variable "east_access_token" {
  description = "The access token for the east Kubernetes cluster"
  type        = string
}

variable "east_region" {
  description = "The region of the east Kubernetes cluster"
  type        = string
}

variable "west_cluster_endpoint" {
  description = "The endpoint of the west Kubernetes cluster to register with ArgoCD"
  type        = string
}

variable "west_cluster_ca_certificate" {
  description = "The CA certificate of the west Kubernetes cluster"
  type        = string
}

variable "west_access_token" {
  description = "The access token for the west Kubernetes cluster"
  type        = string
}

variable "west_region" {
  description = "The region of the west Kubernetes cluster"
  type        = string
}

