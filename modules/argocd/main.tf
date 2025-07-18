resource "google_service_account" "argocd_gcp_sa" {
  account_id   = var.gcp_sa_name
  display_name = "ArgoCD Workload Identity SA"
  project      = var.project_id
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

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = var.namespace
  version    = "8.1.0"

  values = [
    yamlencode({
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
    server = var.east_cluster_endpoint
    config = jsonencode({
      bearerToken = var.east_access_token
      tlsClientConfig = {
        insecure = true
        caData   = var.east_cluster_ca_certificate
      }
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
    server = var.west_cluster_endpoint
    config = jsonencode({
      bearerToken = var.west_access_token
      tlsClientConfig = {
        insecure = true
        caData   = var.west_cluster_ca_certificate
      }
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
    server = var.central_cluster_endpoint
    config = jsonencode({
      bearerToken = var.central_access_token
      tlsClientConfig = {
        insecure = true
        caData   = var.central_cluster_ca_certificate
      }
    })
  }
  depends_on = [helm_release.argocd]
}

resource "helm_release" "mario_applicationset" {
  name       = "mario-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  namespace  = var.namespace

  values = [
    jsonencode({
      applications = []
      applicationsets = [
        {
          name = "demo-applicationset"
          generators = [{
            list = {
              elements = [
                {
                  name      = "mario-east"
                  namespace = "mario"
                  server    = var.east_cluster_endpoint
                  isGateway = false
                },
                {
                  name      = "mario-central"
                  namespace = "mario"
                  server    = var.central_cluster_endpoint
                  isGateway = true
                },
                {
                  name      = "mario-west"
                  namespace = "mario"
                  server    = var.west_cluster_endpoint
                  isGateway = false
                }
              ]
            }
          }]
          template = {
            metadata = {
              name = "{{name}}"
            }
            spec = {
              project = "default"
              source = {
                repoURL        = var.gitops_repo_url
                targetRevision = var.environment
                path           = "helm/mario"
                helm = {
                  parameters = [
                    {
                      name  = "gateway.enable"
                      value = "{{isGateway}}"
                    }
                  ]
                }
              }
              destination = {
                server    = "{{server}}"
                namespace = "{{namespace}}"
              }
              syncPolicy = {
                automated = {
                  prune    = true
                  selfHeal = true
                }
              }
            }
          }
        }
      ]
    })
  ]

  depends_on = [
    helm_release.argocd
  ]
}
