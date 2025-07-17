resource "google_compute_address" "argocd_ip" {
  name   = "argocd-public-ip"
  region = var.region
}

# GCP Service Account for ArgoCD (Workload Identity Federation)
resource "google_service_account" "argocd" {
  account_id   = var.gcp_sa_name
  display_name = "ArgoCD Workload Identity SA"
  project      = var.project_id
}

# Kubernetes Service Account for ArgoCD, annotated for GCP Workload Identity
# Ensure the argocd namespace exists before creating resources in it
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_service_account" "argocd" {
  metadata {
    name      = var.k8s_sa_name
    namespace = "argocd"
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.argocd.email
    }
  }
  depends_on = [kubernetes_namespace.argocd]
  automount_service_account_token = true
}

# IAM policy binding for Workload Identity
resource "google_service_account_iam_member" "workload_identity_binding" {
  service_account_id = google_service_account.argocd.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[argocd/${var.k8s_sa_name}]"
}

# ArgoCD Helm install (Hub or Spoke)
resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "8.1.0"
  create_namespace = true

  set {
    name  = "server.ingress.enabled"
    value = var.is_hub ? "true" : "false"
  }

  set {
    name  = "server.ingress.ingressClassName"
    value = var.is_hub ? "nginx" : ""
  }

  set {
    name  = "server.ingress.annotations.\"kubernetes.io/ingress.global-static-ip-name\""
    value = var.is_hub ? google_compute_address.argocd_ip.name : ""
  }

  set {
    name  = "server.ingress.annotations.\"kubernetes.io/ingress.allow-http\""
    value = var.is_hub ? "true" : ""
  }

  set {
    name  = "server.ingress.ip"
    value = var.is_hub ? google_compute_address.argocd_ip.address : ""
  }

  set {
    name  = "controller.serviceAccount.name"
    value = kubernetes_service_account.argocd.metadata[0].name
  }

  set {
    name  = "controller.serviceAccount.annotations.\"iam.gke.io/gcp-service-account\""
    value = google_service_account.argocd.email
  }

  set {
    name  = "configs.cm.\"application.instanceLabelKey\""
    value = var.is_hub ? "argocd-hub" : "argocd-spoke"
  }
}
