resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.51.4"
  timeout          = 600
  wait             = true
  wait_for_jobs    = true

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  # Add annotations for GCP load balancer
  set {
    name  = "server.service.annotations.cloud\\.google\\.com/load-balancer-type"
    value = "External"
  }

  set {
    name  = "controller.replicas"
    value = var.control_cluster ? 2 : 1
  }

  set {
    name  = "server.replicas"
    value = var.control_cluster ? 2 : 1
  }

  set {
    name  = "repoServer.replicas"
    value = var.control_cluster ? 2 : 1
  }

  # Configure Redis HA if this is a control cluster
  set {
    name  = "redis.enabled"
    value = true
  }
  set {
    name  = "redis-ha.enabled"
    value = var.control_cluster
  }
  # Set admin password from Secret Manager (plaintext) or provided hash
  dynamic "set" {
    for_each = local.use_plaintext_password ? [1] : []
    content {
      name  = "configs.secret.argocdServerAdminPasswordMtime"
      value = "1" # Force password update on changes
    }
  }

  dynamic "set" {
    for_each = local.use_plaintext_password ? [1] : []
    content {
      name  = "configs.secret.argocdServerAdminPassword"
      value = local.admin_password
    }
  }

  dynamic "set" {
    for_each = !local.use_plaintext_password && local.admin_password_hash != null ? [1] : []
    content {
      name  = "configs.secret.argocdServerAdminPassword"
      value = local.admin_password_hash
    }
  }

  # Control creation of password secret
  set {
    name  = "configs.secret.createSecret"
    value = local.use_plaintext_password || local.admin_password_hash != null ? true : false
  }

  # Configure SSO integration if enabled
  dynamic "set" {
    for_each = var.enable_sso ? [1] : []
    content {
      name  = "configs.cm.dex.config"
      value = var.dex_config
    }
  }

  # ConfigMap custom settings
  set {
    name  = "configs.cm.application\\.resourceTrackingMethod"
    value = "annotation"
  }

  set {
    name  = "configs.cm.timeout\\.reconciliation"
    value = "180s"
  }

  # Allow ApplicationSets to create resources across all registered clusters
  set {
    name  = "applicationSet.enabled"
    value = true
  }

  set {
    name  = "applicationSet.replicaCount"
    value = var.control_cluster ? 2 : 1
  }

  # Configure Notifications
  set {
    name  = "notifications.enabled"
    value = true
  }
  values = [<<-EOT
    server:
      extraArgs:
        - --insecure
      config:
        url: "${var.argocd_url}"
      service:
        annotations:
          cloud.google.com/neg: '{"ingress": true}'
      additionalApplications:
      - name: cluster-resources
        namespace: argocd
        destination:
          server: https://kubernetes.default.svc
          namespace: argocd
        project: default
        source:
          repoURL: "${var.gitops_repo_url}"
          targetRevision: ${var.gitops_repo_branch}
          path: cluster-resources
        syncPolicy:
          automated:
            prune: true
            selfHeal: true

    applicationSet:
      extraRules:
        - apiGroups: [""]
          resources: ["*"]
          verbs: ["*"]
    EOT
  ]
}

# Create ClusterRoleBinding for ArgoCD to allow multi-cluster management
resource "kubernetes_cluster_role_binding" "argocd_cluster_admin" {
  metadata {
    name = "argocd-application-controller-cluster-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "argocd-application-controller"
    namespace = "argocd"
  }

  depends_on = [helm_release.argocd]
}

# Create registrations for remote clusters if this is the control cluster
resource "kubernetes_secret" "remote_cluster_secrets" {
  for_each = var.control_cluster ? { for idx, cluster in var.remote_clusters : cluster.name => cluster } : {}

  provider = kubernetes

  metadata {
    name      = "cluster-${each.value.name}"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
    }
  }

  data = {
    name   = each.value.name
    server = each.value.endpoint
    config = jsonencode({
      bearerToken = each.value.token
      tlsClientConfig = {
        insecure = false
        caData   = each.value.ca_certificate
      }
    })
  }

  depends_on = [helm_release.argocd]
}

# Create a ConfigMap for the application projects
resource "kubernetes_config_map" "argocd_projects" {
  count = var.control_cluster ? 1 : 0

  metadata {
    name      = "argocd-projects"
    namespace = "argocd"
  }

  data = {
    "projects.yaml" = <<-EOT
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: argocd-projects
      namespace: argocd
    data:
      default-project: |
        project: default
        sourceRepos:
        - '*'
        destinations:
        - namespace: '*'
          server: '*'
        clusterResourceWhitelist:
        - group: '*'
          kind: '*'
    EOT
  }

  depends_on = [helm_release.argocd]
}

resource "time_sleep" "wait_for_lb_ip" {
  depends_on      = [helm_release.argocd]
  create_duration = "30s"
}

data "kubernetes_service" "argocd_server" {
  depends_on = [time_sleep.wait_for_lb_ip]

  metadata {
    name      = "argocd-server"
    namespace = "argocd"
  }
}
