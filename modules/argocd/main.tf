locals {
  rendered_values = templatefile("${path.module}/values.yaml.tpl", {
    gitops_repo_url          = var.gitops_repo_url
    environment              = var.environment
    namespace                = var.namespace
    app_namespace            = "mario"
    east_cluster_endpoint    = var.east_cluster_endpoint
    central_cluster_endpoint = var.central_cluster_endpoint
    west_cluster_endpoint    = var.west_cluster_endpoint
  })
}

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
          argocdServerAdminPassword = bcrypt(data.google_secret_manager_secret_version.argocd_admin_password.secret_data)
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
    kubernetes_service_account.argocd_k8s,
    terraform_data.cleanup_argocd_apps
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

resource "helm_release" "mario_apps" {
  name       = "mario-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  namespace  = var.namespace
  version    = "2.0.2"

  values = [local.rendered_values]

  depends_on = [
    helm_release.argocd,
    kubernetes_secret.argocd_east_cluster,
    kubernetes_secret.argocd_west_cluster,
    kubernetes_secret.argocd_central_cluster
  ]
}

resource "terraform_data" "cleanup_argocd_apps" {
  triggers_replace = {
    namespace = var.namespace
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      echo "Cleaning up ArgoCD Applications in namespace: ${self.triggers_replace.namespace}"

      # Delete Applications
      APPS=$(kubectl get applications.argoproj.io -n ${self.triggers_replace.namespace} -o name || true)
      if [ ! -z "$APPS" ]; then
        echo "Deleting Applications: $APPS"
        kubectl delete $APPS -n ${self.triggers_replace.namespace} || true
      fi

      # Delete ApplicationSets
      APPSETS=$(kubectl get applicationsets.argoproj.io -n ${self.triggers_replace.namespace} -o name || true)
      if [ ! -z "$APPSETS" ]; then
        echo "Deleting ApplicationSets: $APPSETS"
        kubectl delete $APPSETS -n ${self.triggers_replace.namespace} || true
      fi

      # Delete AppProjects
      APPPROJS=$(kubectl get appprojects.argoproj.io -n ${self.triggers_replace.namespace} -o name || true)
      if [ ! -z "$APPPROJS" ]; then
        echo "Deleting AppProjects: $APPPROJS"
        kubectl delete $APPPROJS -n ${self.triggers_replace.namespace} || true
      fi

      echo "Waiting for workloads to clean up..."
      sleep 30
    EOT
  }

  depends_on = [ helm_release.mario_apps ]
}