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

# Use an external program to generate a bcrypt hash of the password
resource "null_resource" "bcrypt_password" {
  count = var.admin_password_secret_name != "" ? 1 : 0

  triggers = {
    secret_id = var.admin_password_secret_name
    version   = "latest"
  }
}

locals {
  # We require the secret to exist in Secret Manager
  admin_password_raw = var.admin_password_secret_name != "" ? data.google_secret_manager_secret_version.argocd_admin_password[0].secret_data : null

  # ArgoCD requires password to be bcrypt hashed. It will be used as is from Secret Manager.
  # Make sure your password in Secret Manager is already properly hashed or in plaintext if you want ArgoCD to hash it.
  admin_password = local.admin_password_raw
}
