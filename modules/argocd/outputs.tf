output "argocd_endpoint" {
  description = "The endpoint of the ArgoCD server"
  value       = helm_release.argocd.status.load_balancer_ingress[0]
}
