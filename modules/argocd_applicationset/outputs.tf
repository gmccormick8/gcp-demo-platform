output "applicationset_status" {
  description = "Status of the ArgoCD ApplicationSet"
  value       = kubernetes_manifest.applicationset.status
}
