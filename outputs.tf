output "vpc_details" {
  description = "VPC network details"
  value = {
    network_name = module.demo-vpc.network.name
  }
}

output "gke_cluster_endpoints" {
  description = "Endpoints for each GKE cluster"
  value = {
    for key, cluster in module.gke_clusters : key => cluster.cluster_endpoint
  }
}

output "argocd_endpoints" {
  description = "Endpoints for ArgoCD servers in each cluster"
  value = {
    central = module.argocd_central.argocd_endpoint
    east    = module.argocd_east.argocd_endpoint
    west    = module.argocd_west.argocd_endpoint
  }
}
