terraform {
  required_version = "~> 1.11"

  required_providers {
    kubernetes = {
      source                = "hashicorp/kubernetes"
      version               = "~> 2.30"
      configuration_aliases = [kubernetes.east, kubernetes.west]
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 6.30"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}
