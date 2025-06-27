# Create namespace for ArgoCD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

# Create templated values.yaml file for ArgoCD
locals {
  # Convert legacy parameters to new format for backward compatibility
  effective_argocd_config = {
    hostname                     = coalesce(var.argocd_config.hostname, var.ingress_enabled ? var.ingress_host : "")
    values_yaml                  = coalesce(var.argocd_config.values_yaml, var.custom_helm_values)
    redis_ha_enabled             = var.argocd_config.redis_ha_enabled != null ? var.argocd_config.redis_ha_enabled : var.ha_enabled
    autoscaling_enabled          = var.argocd_config.autoscaling_enabled
    slack_notification_token     = var.argocd_config.slack_notification_token
    argocd_notifications_enabled = var.argocd_config.argocd_notifications_enabled
    ingress_class_name           = coalesce(var.argocd_config.ingress_class_name, "gce")
  }

  # Merge values from templates and custom values
  values_content = templatefile("${path.module}/templates/values.yaml", {
    server_replica_count   = local.effective_argocd_config.redis_ha_enabled ? 3 : 1
    server_service_type    = var.server_service_type
    reconciliation_timeout = "180s"
  })
}

# Deploy ArgoCD with Helm
resource "helm_release" "argocd" {
  depends_on = [kubernetes_namespace.argocd]

  name       = "argo-cd"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = var.namespace
  repository = "https://argoproj.github.io/argo-helm"
  timeout    = 600

  values = [
    local.values_content,
    local.effective_argocd_config.values_yaml
  ]

  # Set admin password if provided
  set_sensitive {
    name = "configs.secret.argocdServerAdminPassword"
    value = var.admin_password != "" ? var.admin_password : (
      var.admin_password_secret_id != "" ? data.google_secret_manager_secret_version.argocd_admin_password[0].secret_data : ""
    )
  }

  # Configure ingress if hostname is provided
  set {
    name  = "server.ingress.enabled"
    value = local.effective_argocd_config.hostname != "" ? true : false
  }

  set {
    name  = "server.ingress.hosts[0]"
    value = local.effective_argocd_config.hostname
  }

  set {
    name  = "server.ingress.ingressClassName"
    value = local.effective_argocd_config.ingress_class_name
  }

  # Configure Slack notifications if token is provided
  set {
    name  = "notifications.enabled"
    value = local.effective_argocd_config.argocd_notifications_enabled
  }

  set_sensitive {
    name  = "notifications.secret.items.slack-token"
    value = local.effective_argocd_config.slack_notification_token
  }

  # Configure autoscaling if enabled
  set {
    name  = "controller.autoscaling.enabled"
    value = local.effective_argocd_config.autoscaling_enabled
  }

  set {
    name  = "server.autoscaling.enabled"
    value = local.effective_argocd_config.autoscaling_enabled
  }

  set {
    name  = "repoServer.autoscaling.enabled"
    value = local.effective_argocd_config.autoscaling_enabled
  }
}

# Create ArgoCD Projects
resource "helm_release" "argocd_projects" {
  for_each   = var.argocd_projects
  depends_on = [helm_release.argocd]

  name       = "argocd-project-${each.key}"
  chart      = "argocd-project"
  repository = "https://argoproj.github.io/argo-helm"
  namespace  = var.namespace

  values = [
    yamlencode({
      project = {
        name        = each.value.name
        description = each.value.description
        namespace   = var.namespace
        sourceRepos = each.value.source_repos
        destinations = [for dest in each.value.destinations : {
          server    = dest.server
          namespace = dest.namespace
        }]
        clusterResourceWhitelist = [
          {
            group = "*"
            kind  = "*"
          }
        ]
      }
    })
  ]
}

# Create ArgoCD Applications
resource "helm_release" "argocd_applications" {
  for_each   = var.argocd_applications
  depends_on = [helm_release.argocd, helm_release.argocd_projects]

  name       = "argocd-app-${each.key}"
  chart      = "argocd-application"
  repository = "https://argoproj.github.io/argo-helm"
  namespace  = var.namespace

  values = [
    yamlencode({
      application = {
        name      = each.value.name
        namespace = var.namespace
        project   = lookup(each.value, "project", "default")
        source = {
          repoURL        = each.value.repo_url
          targetRevision = each.value.target_revision
          path           = each.value.path
          helm = each.value.helm_values != null ? {
            values     = each.value.helm_values.raw_values
            valueFiles = coalesce(each.value.helm_values.value_files, [])
          } : null
        }
        destination = {
          server    = lookup(each.value.destination, "server", "https://kubernetes.default.svc")
          namespace = each.value.destination.namespace
        }
        syncPolicy = each.value.sync_policy != null ? {
          automated = {
            prune      = each.value.sync_policy.automated.prune
            selfHeal   = each.value.sync_policy.automated.self_heal
            allowEmpty = lookup(each.value.sync_policy.automated, "allow_empty", false)
          }
          syncOptions = each.value.sync_policy.sync_options
          } : {
          automated = {
            prune      = true
            selfHeal   = true
            allowEmpty = false
          }
          syncOptions = ["CreateNamespace=true"]
        }
      }
    })
  ]
}

# Retrieve the ArgoCD admin password from Secret Manager if specified
data "google_secret_manager_secret_version" "argocd_admin_password" {
  count   = var.admin_password_secret_id != "" ? 1 : 0
  secret  = var.admin_password_secret_id
  version = "latest"
}

# Store the ArgoCD admin password secret
data "kubernetes_secret" "argocd_admin_password" {
  depends_on = [helm_release.argocd]
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = var.namespace
  }
}
