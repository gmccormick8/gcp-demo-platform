data "google_secret_manager_secret" "argocd_admin_password" {
  count     = var.admin_password_secret_name != "" ? 1 : 0
  project   = var.project_id
  secret_id = var.admin_password_secret_name
}

data "google_secret_manager_secret_version" "argocd_admin_password" {
  count   = var.admin_password_secret_name != "" ? 1 : 0
  project = var.project_id
  secret  = var.admin_password_secret_name
  version = "latest"
}

locals {
  # We require the secret to exist in Secret Manager
  admin_password = var.admin_password_secret_name != "" ? data.google_secret_manager_secret_version.argocd_admin_password[0].secret_data : null
}
