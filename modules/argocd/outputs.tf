output "argocd_namespace" {
  description = "The Kubernetes namespace where ArgoCD is installed"
  value       = var.namespace
}

output "argocd_server_service_name" {
  description = "The name of the ArgoCD server Kubernetes service"
  value       = "argo-cd-argocd-server"
}

output "argocd_url" {
  description = "The URL to access ArgoCD UI"
  value       = local.effective_argocd_config.hostname != "" ? "https://${local.effective_argocd_config.hostname}" : null
}

output "argocd_admin_username" {
  description = "The ArgoCD admin username"
  value       = "admin"
}

output "argocd_admin_password" {
  description = "The ArgoCD admin password"
  value = var.admin_password != "" ? var.admin_password : (
    var.admin_password_secret_id != "" ?
    data.google_secret_manager_secret_version.argocd_admin_password[0].secret_data :
    try(data.kubernetes_secret.argocd_admin_password.data.password, "")
  )
  sensitive = true
}

output "application_names" {
  description = "List of ArgoCD applications created"
  value       = [for app in var.argocd_applications : app.name]
}

output "project_names" {
  description = "List of ArgoCD projects created"
  value       = [for project in var.argocd_projects : project.name]
}
