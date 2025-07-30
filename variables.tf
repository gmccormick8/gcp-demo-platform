variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "subnets" {
  description = "Map of subnets to create, including secondary ranges"
  type = map(object({
    region = string
    cidr   = string
    secondary_ranges = map(object({
      ip_cidr_range = string
    }))
  }))
}

variable "clusters" {
  description = "Map of GKE clusters with their configurations"
  type = map(object({
    cluster_name          = string
    region                = string
    zone                  = string
    subnet_key            = string
    pods_network_name     = string
    services_network_name = string
    master_ipv4_cidr      = string
  }))
}

variable "min_node_count" {
  description = "Minimum number of nodes in the GKE cluster"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes in the GKE cluster"
  type        = number
}

variable "machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
}

variable "disk_size_gb" {
  description = "Disk size in GB for GKE nodes"
  type        = number
}

variable "disk_type" {
  description = "Disk type for GKE nodes"
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

variable "argocd_namespace" {
  description = "Kubernetes namespace name for ArgoCD"
  type        = string
}
