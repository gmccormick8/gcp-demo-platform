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
  value       = "Plaintext password stored in Secret Manager: ${var.admin_password_secret_name}"
}

output "server_service_name" {
  description = "Service name for the ArgoCD server"
  value       = "argocd-server"
}

output "external_ip" {
  description = "External IP address assigned to the ArgoCD server LoadBalancer"
  value       = length(data.kubernetes_service.argocd_server.status) > 0 ? data.kubernetes_service.argocd_server.status.0.load_balancer.0.ingress.0.ip : ""
}
