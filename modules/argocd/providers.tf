terraform {
  required_version = "~> 1.11"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.30"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
  }
}

provider "kubernetes" {
  host                   = "https://${var.clusters["central"].endpoint}"
  token                  = var.clusters["central"].access_token
  cluster_ca_certificate = base64decode(var.clusters["central"].ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${var.clusters["central"].endpoint}"
    token                  = var.clusters["central"].access_token
    cluster_ca_certificate = base64decode(var.clusters["central"].ca_certificate)
  }
}
