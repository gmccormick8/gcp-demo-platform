module "argocd" {
  source  = "squareops/argocd/kubernetes"
  version = "3.0.1"

  name             = "argocd"
  namespace        = var.namespace
  namespace_create = true
  admin_password   = var.admin_password

  # ArgoCD configuration
  ha_enabled          = var.ha_enabled
  server_insecure     = var.server_insecure
  create_ingress      = var.ingress_enabled
  ingress_annotations = var.ingress_annotations
  ingress_host        = var.ingress_host
  ingress_tls         = var.ingress_tls
  service_type        = var.server_service_type

  # Repository and application configuration
  repo_url        = var.gitops_repo_url
  target_revision = var.environment
  helm_values     = var.custom_helm_values

  # Applications configuration
  applications = { for k, v in var.argocd_applications : k => {
    name                   = v.name
    namespace              = v.destination.namespace
    create_namespace       = true
    project                = lookup(v, "project", "default")
    source_path            = v.path
    source_repo            = v.repo_url
    source_target_revision = v.target_revision

    # Destination
    destination_server = lookup(v.destination, "server", "https://kubernetes.default.svc")

    # Sync policy
    auto_prune     = v.sync_policy != null ? v.sync_policy.automated.prune : true
    auto_self_heal = v.sync_policy != null ? v.sync_policy.automated.self_heal : true

    # Helm values if provided
    helm_values       = v.helm_values != null ? v.helm_values.raw_values : ""
    helm_values_files = v.helm_values != null ? v.helm_values.value_files : []
  } }

  # Projects configuration
  projects = { for k, v in var.argocd_projects : k => {
    name        = v.name
    description = v.description
    namespace   = var.namespace

    # Source repositories
    source_repos = v.source_repos

    # Destination configuration
    destinations = [for dest in v.destinations : {
      server    = dest.server
      namespace = dest.namespace
    }]

    # Default cluster permissions
    cluster_resource_whitelist = [
      {
        group = "*"
        kind  = "*"
      }
    ]
    namespace_resource_blacklist = []
  } }

  depends_on = []
}

# Retrieve the ArgoCD admin password from Secret Manager if specified
data "google_secret_manager_secret_version" "argocd_admin_password" {
  count   = var.admin_password_secret_id != "" ? 1 : 0
  secret  = var.admin_password_secret_id
  version = "latest"
}
