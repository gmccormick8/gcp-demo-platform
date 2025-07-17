resource "google_compute_address" "argocd_ip" {
  name   = "argocd-public-ip"
  region = var.region
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "8.1.0"

  create_namespace = true

  set {
    name  = "server.ingress.enabled"
    value = "true"
  }

  set {
    name  = "server.ingress.ingressClassName"
    value = "nginx"
  }

  set {
    name  = "server.ingress.annotations.\"kubernetes.io/ingress.global-static-ip-name\""
    value = google_compute_address.argocd_ip.name
  }

  set {
    name  = "server.ingress.annotations.\"kubernetes.io/ingress.allow-http\""
    value = "true"
  }

  set {
    name  = "server.ingress.ip"
    value = google_compute_address.argocd_ip.address
  }

}
