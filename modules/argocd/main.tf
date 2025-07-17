resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "google_service_account" "argocd_gcp_sa" {
  account_id   = var.gcp_sa_name
  display_name = "ArgoCD Workload Identity SA"
  project      = var.project_id
}

resource "kubernetes_service_account" "argocd_k8s" {
  metadata {
    name      = var.k8s_sa_name
    namespace = "argocd"
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.argocd_gcp_sa.email
    }
  }
  depends_on = [kubernetes_namespace.argocd]
}

resource "google_service_account_iam_binding" "workload_identity_binding" {
  service_account_id = google_service_account.argocd_gcp_sa.name
  role               = "roles/iam.workloadIdentityUser"
  members            = ["serviceAccount:${var.project_id}.svc.id.goog[${kubernetes_namespace.argocd.metadata[0].name}/${kubernetes_service_account.argocd_k8s.metadata[0].name}]"]

}


# Install ArgoCD using the official Helm chart
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "8.1.0"

  values = [
    yamlencode({
      server : {
        serviceAccount : {
          create = false
          name   = kubernetes_service_account.argocd_k8s.metadata[0].name
        }
      }
      controller : {
        serviceAccount : {
          create = false
          name   = kubernetes_service_account.argocd_k8s.metadata[0].name
        }
      }
      repoServer : {
        serviceAccount : {
          create = false
          name   = kubernetes_service_account.argocd_k8s.metadata[0].name
        }
      }
      applicationSet : {
        serviceAccount : {
          create = false
          name   = kubernetes_service_account.argocd_k8s.metadata[0].name
        }
      }
    })
  ]

  depends_on = [
    kubernetes_service_account.argocd_k8s
  ]
}
