provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    token                  = var.access_token
    cluster_ca_certificate = var.cluster_ca_certificate
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  chart            = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  namespace        = var.namespace
  create_namespace = true
  version          = var.chart_version

  values = [
    <<EOT
    server:
      service:
        type: LoadBalancer
    EOT
  ]
}

resource "kubernetes_manifest" "argocd_applicationset" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "ApplicationSet"
    metadata = {
      name      = "helm-applicationset"
      namespace = var.namespace
    }
    spec = {
      generators = [
        {
          git = {
            repoURL  = var.gitops_repo_url
            revision = var.environment
            files = [
              {
                path = "helm/mario/*.yaml"
              }
            ]
          }
        }
      ]
      template = {
        metadata = {
          name = "{{path.basename}}"
        }
        spec = {
          project = "default"
          source = {
            repoURL        = var.gitops_repo_url
            targetRevision = var.environment
            chart          = "{{path.basename}}"
          }
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "{{path.basename}}"
          }
        }
      }
    }
  }
}