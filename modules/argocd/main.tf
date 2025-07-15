data "google_client_config" "current" {
}

data "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.cluster_location
}

module "argocd" {
  source = "squareops/argocd/kubernetes"
  argocd_config = {
    hostname    = "argocd.prod.in"
    values_yaml = ""
  }
}