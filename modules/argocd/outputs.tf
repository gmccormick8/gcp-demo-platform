output "argocd_release" {
  value       = helm_release.argocd
  description = "ArgoCD Helm release info"
}