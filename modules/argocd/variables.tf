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