output "gke_cluster_endpoints" {
  description = "Public Endpoints for each GKE cluster"
  value = {
    for key, cluster in module.gke_clusters : key => cluster.cluster_endpoint
  }
}

output "argocd_server_url" {
  description = "ArgoCD URL"
  value       = module.argocd_central.argocd_release.argocd_server_url
}