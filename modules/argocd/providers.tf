terraform {
  required_version = "~> 1.11"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.30.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.0"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0.0"
    }
  }
}
