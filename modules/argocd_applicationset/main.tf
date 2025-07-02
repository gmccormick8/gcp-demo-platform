provider "kubernetes" {
  alias                  = "argocd"
  host                   = var.clusters["central"]
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke_clusters["central"].master_auth.cluster_ca_certificate)
}

resource "kubernetes_manifest" "applicationset" {
  provider = kubernetes.argocd

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "ApplicationSet"
    metadata = {
      name      = var.application_name
      namespace = var.argocd_namespace
    }
    spec = {
      generators = [
        {
          list = {
            elements = [
              {
                cluster = "east"
                url     = var.clusters["east"]
              },
              {
                cluster = "central"
                url     = var.clusters["central"]
              },
              {
                cluster = "west"
                url     = var.clusters["west"]
              }
            ]
          }
        }
      ]
      template = {
        metadata = {
          name = "${var.application_name}-{{cluster}}"
        }
        spec = {
          project = "default"
          source = {
            repoURL        = var.repo_url
            targetRevision = var.target_revision
            path           = var.path
          }
          destination = {
            server    = "{{url}}"
            namespace = "default"
          }
        }
      }
    }
  }
}
