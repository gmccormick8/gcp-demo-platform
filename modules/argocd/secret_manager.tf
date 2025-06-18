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

locals {
  # Check if secret exists and has a version
  secret_exists = var.admin_password_secret_name != "" && length(data.google_secret_manager_secret_version.argocd_admin_password) > 0

  # Use the secret if it exists, otherwise use the provided hash
  # No default password should be used - this now requires the secret to be set in Secret Manager
  admin_password_hash = local.secret_exists ? data.google_secret_manager_secret_version.argocd_admin_password[0].secret_data : (
    var.admin_password_hash != "" ? var.admin_password_hash : null
  )
}
