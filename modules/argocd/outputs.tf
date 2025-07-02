output "argocd_server_url" {
  description = "The URL of the ArgoCD server"
  value       = helm_release.argocd.status[0].url
}
