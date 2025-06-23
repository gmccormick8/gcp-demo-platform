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
    network_id   = module.demo-vpc.network_id
  }
}

output "argocd_info" {
  description = "ArgoCD deployment information"
  value = {
    namespace       = module.argocd.argocd_namespace
    service_name    = module.argocd.argocd_server_service
    control_cluster = local.clusters.central.control_cluster
    admin_username  = "admin"
  }
}
