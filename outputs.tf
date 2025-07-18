output "gke_cluster_public_endpoints" {
  description = "Public Endpoints for each GKE cluster"
  value = {
    for key, cluster in module.gke_clusters : key => cluster.cluster_endpoint
  }
}

output "gke_cluster_private_endpoints" {
  description = "Private Endpoints for each GKE cluster"
  value = {
    for key, cluster in module.gke_clusters : key => cluster.cluster_private_endpoint
  }
}
