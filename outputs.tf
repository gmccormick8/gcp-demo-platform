output "gke_clusters" {
  description = "GKE cluster details"
  value = {
    for key, cluster in module.gke_clusters : key => {
      name     = cluster.cluster_name
      endpoint = cluster.cluster_endpoint
      location = cluster.cluster_location
    }
  }
}

output "vpc_details" {
  description = "VPC network details"
  value = {
    network_name = module.demo-vpc.network.name
  }
}

output "argocd_server_url" {
  description = "The URL of the ArgoCD server"
  value       = module.argocd.argocd_server_url
}

output "applicationset_status" {
  description = "Status of the ArgoCD ApplicationSet"
  value       = module.argocd_applicationset.applicationset_status
}
