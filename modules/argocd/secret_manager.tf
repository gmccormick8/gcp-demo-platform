data "google_secret_manager_secret" "argocd_admin_password" {
  count     = var.admin_password_secret_name != "" ? 1 : 0
  project   = var.project_id
  secret_id = var.admin_password_secret_name
}

data "google_secret_manager_secret_version" "argocd_admin_password" {
  count   = var.admin_password_secret_name != "" && length(data.google_secret_manager_secret.argocd_admin_password) > 0 ? 1 : 0
  project = var.project_id
  secret  = var.admin_password_secret_name
  version = "latest"
}

resource "random_password" "argocd_admin" {
  count   = var.admin_password_secret_name == "" && var.admin_password_hash == "" ? 1 : 0
  length  = 16
  special = true
}

locals {
  # Check if secret exists and has a version
  secret_exists = var.admin_password_secret_name != "" && length(data.google_secret_manager_secret_version.argocd_admin_password) > 0

  # Get the plaintext password from either:
  # 1. Secret Manager (preferred, unhashed)
  # 2. Provided hash directly
  # 3. Auto-generated password as fallback
  admin_password = local.secret_exists ? data.google_secret_manager_secret_version.argocd_admin_password[0].secret_data : (
    var.admin_password_hash != "" ? null : (
      length(random_password.argocd_admin) > 0 ? random_password.argocd_admin[0].result : null
    )
  )

  # If we have a plaintext password, use it directly in the ArgoCD configs
  # Otherwise, use the provided hash (legacy support)
  use_plaintext_password = local.admin_password != null
  admin_password_hash    = var.admin_password_hash != "" ? var.admin_password_hash : null
}
