output "argocd_namespace" {
  description = "Namespace where ArgoCD is deployed"
  value       = "argocd"
}

output "argocd_server_service" {
  description = "Name of the ArgoCD server service"
  value       = helm_release.argocd.name
}

output "argocd_server_admin_password_info" {
  description = "Information about the ArgoCD admin password"
  value       = var.admin_password_secret_name != "" ? "Stored in Secret Manager: ${var.admin_password_secret_name}" : (var.admin_password_hash != "" ? "Custom password hash provided" : "No password provided - manual configuration required")
}
