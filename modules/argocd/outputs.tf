output "argocd_namespace" {
  description = "The Kubernetes namespace where ArgoCD is installed"
  value       = module.argocd.namespace
}

output "argocd_server_service_name" {
  description = "The name of the ArgoCD server Kubernetes service"
  value       = module.argocd.argocd_server_service_name
}

output "argocd_url" {
  description = "The URL to access ArgoCD UI"
  value       = var.ingress_enabled ? "https://${var.ingress_host}" : null
}

output "argocd_admin_username" {
  description = "The ArgoCD admin username"
  value       = "admin"
}

output "argocd_admin_password" {
  description = "The ArgoCD admin password"
  value       = var.admin_password != "" ? var.admin_password : (var.admin_password_secret_id != "" ? data.google_secret_manager_secret_version.argocd_admin_password[0].secret_data : module.argocd.argocd_admin_password)
  sensitive   = true
}

output "application_names" {
  description = "List of ArgoCD applications created"
  value       = module.argocd.application_names
}

output "project_names" {
  description = "List of ArgoCD projects created"
  value       = module.argocd.project_names
}
