provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_ca_cert)
    token                  = var.access_token
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  chart      = var.argocd_helm_chart
  repository = var.argocd_helm_repo
  version    = var.argocd_version

  namespace = kubernetes_namespace.argocd.metadata[0].name

  values = [
    jsonencode(var.argocd_values)
  ]
}
