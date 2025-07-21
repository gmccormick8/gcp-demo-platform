resource "google_service_account" "argocd_gcp_sa" {
  account_id   = var.gcp_sa_name
  display_name = "ArgoCD Workload Identity SA"
  project      = var.project_id
}

resource "google_project_iam_member" "argocd_secretmanager" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.argocd_gcp_sa.email}"
}

resource "kubernetes_service_account" "argocd_k8s" {
  metadata {
    name      = var.k8s_sa_name
    namespace = var.namespace
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.argocd_gcp_sa.email
    }
  }
}

resource "google_service_account_iam_binding" "workload_identity_binding" {
  service_account_id = google_service_account.argocd_gcp_sa.name
  role               = "roles/iam.workloadIdentityUser"
  members            = ["serviceAccount:${var.project_id}.svc.id.goog[${var.namespace}/${kubernetes_service_account.argocd_k8s.metadata[0].name}]"]
}

data "google_secret_manager_secret_version" "argocd_admin_password" {
  project = var.project_id
  secret  = "argocd-admin-password-${var.environment}"
}

data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = var.namespace
  }
  depends_on = [helm_release.argocd]
}

resource "kubernetes_secret" "argocd_admin_secret" {
  metadata {
    name      = "argocd-secret"
    namespace = "argocd"
  }

  data = {
    "admin.password"      = base64encode(bcrypt(data.google_secret_manager_secret_version.argocd_admin_password.secret_data))
    "admin.passwordMtime" = base64encode(timestamp())
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = var.namespace
  version    = "8.1.0"

  values = [
    yamlencode({
      configs = {
        secret = {
          argocdServerAdminPassword = kubernetes_secret.argocd_admin_secret.data["admin.password"]
          adminPasswordMtime        = kubernetes_secret.argocd_admin_secret.data["admin.passwordMtime"]
        }
      }
      server : {
        serviceAccount : {
          create = false
          name   = kubernetes_service_account.argocd_k8s.metadata[0].name
        }
        service : {
          type = "LoadBalancer"
          ports = {
            http = 80
          }
        }
        ingress : {
          enabled = true
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

resource "kubernetes_config_map_v1" "argocd_cm" {
  metadata {
    name      = "argocd-cm"
    namespace = var.namespace

    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }

    annotations = {
      "meta.helm.sh/release-name"      = "argocd"
      "meta.helm.sh/release-namespace" = var.namespace
    }
  }

  data = {
    "timeout.reconciliation" = "60s"
  }
}

resource "kubernetes_secret" "argocd_east_cluster" {
  metadata {
    name      = "argocd-cluster-east"
    namespace = var.namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
    }
  }
  data = {
    name   = "east"
    server = "https://${var.east_cluster_endpoint}"
    config = jsonencode({
      tlsClientConfig = {
        insecure = false
        caData   = var.east_cluster_ca_certificate
      }
      bearerToken = var.east_access_token
    })
  }
  depends_on = [helm_release.argocd]
}

resource "kubernetes_secret" "argocd_west_cluster" {
  metadata {
    name      = "argocd-cluster-west"
    namespace = var.namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
    }
  }
  data = {
    name   = "west"
    server = "https://${var.west_cluster_endpoint}"
    config = jsonencode({
      tlsClientConfig = {
        insecure = false
        caData   = var.west_cluster_ca_certificate
      }
      bearerToken = var.west_access_token
    })
  }
  depends_on = [helm_release.argocd]
}

resource "kubernetes_secret" "argocd_central_cluster" {
  metadata {
    name      = "argocd-cluster-central"
    namespace = var.namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
    }
  }
  data = {
    name   = "central"
    server = "https://${var.central_cluster_endpoint}"
    config = jsonencode({
      tlsClientConfig = {
        insecure = false
        caData   = var.central_cluster_ca_certificate
      }
      bearerToken = var.central_access_token
    })
  }
  depends_on = [helm_release.argocd]
}

resource "helm_release" "mario_application" {
  name       = "mario-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  namespace  = var.namespace

  values = [
    yamlencode({
      applications = {
        "mario-east" = {
          name      = "mario-east"
          namespace = var.namespace
          project   = "default"
          source = {
            repoURL        = var.gitops_repo_url
            targetRevision = var.environment
            path           = "helm/mario"
            helm = {
              values = yamlencode({
                gateway = {
                  enable = false
                }
                global = {
                  environment = var.environment
                }
              })
            }
          }
          destination = {
            server    = "https://${var.east_cluster_endpoint}"
            namespace = "mario"
          }
          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
            syncOptions = ["CreateNamespace=true"]
          }
        }
        "mario-central" = {
          name      = "mario-central"
          namespace = var.namespace
          project   = "default"
          source = {
            repoURL        = var.gitops_repo_url
            targetRevision = var.environment
            path           = "helm/mario"
            helm = {
              values = yamlencode({
                gateway = {
                  enable = true
                }
                global = {
                  environment = var.environment
                }
              })
            }
          }
          destination = {
            server    = "https://${var.central_cluster_endpoint}"
            namespace = "mario"
          }
          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
            syncOptions = ["CreateNamespace=true"]
          }
        }
        "mario-west" = {
          name      = "mario-west"
          namespace = var.namespace
          project   = "default"
          source = {
            repoURL        = var.gitops_repo_url
            targetRevision = var.environment
            path           = "helm/mario"
            helm = {
              values = yamlencode({
                gateway = {
                  enable = false
                }
                global = {
                  environment = var.environment
                }
              })
            }
          }
          destination = {
            server    = "https://${var.west_cluster_endpoint}"
            namespace = "mario"
          }
          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
            syncOptions = ["CreateNamespace=true"]
          }
        }
      }
    })
  ]

  depends_on = [
    helm_release.argocd,
    kubernetes_secret.argocd_east_cluster,
    kubernetes_secret.argocd_west_cluster,
    kubernetes_secret.argocd_central_cluster
  ]
}
