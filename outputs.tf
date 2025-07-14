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
