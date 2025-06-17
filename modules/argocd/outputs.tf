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
  value       = var.admin_password_secret_name != "" ? "Stored in Secret Manager: ${var.admin_password_secret_name}" : (var.admin_password_hash != "" ? "Custom password hash provided" : "Using default password: argocd123")
}

output "access_instructions" {
  description = "Instructions for accessing ArgoCD UI via port-forwarding"
  value       = <<-EOT
    To access ArgoCD UI:
    1. Run: kubectl port-forward svc/argocd-server -n argocd 8080:443
    2. Open: https://localhost:8080 in your browser
    3. Login with username: admin and password from your secret manager or as provided during deployment
    4. Accept the self-signed certificate warning in your browser
  EOT
}
