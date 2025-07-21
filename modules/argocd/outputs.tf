output "argocd_release" {
  value       = helm_release.argocd
  description = "ArgoCD Helm release info"
}

output "argocd_server_url" {
  description = "The URL of the ArgoCD server"
  value       = "http://${data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].ip}"
}
