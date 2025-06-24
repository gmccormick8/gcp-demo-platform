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
    namespace           = module.argocd.argocd_namespace
    service_name        = module.argocd.argocd_server_service
    server_service_name = module.argocd.server_service_name
    admin_username      = "admin"
    gitops_repo         = var.gitops_repo_url != "" ? var.gitops_repo_url : "https://github.com/gmccormick8/gcp-demo-platform-app.git"
    gitops_branch       = var.environment
    loadbalancer_ip_cmd = "kubectl --context=${local.clusters.central.cluster_name} get svc -n ${module.argocd.argocd_namespace} ${module.argocd.server_service_name} -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
  }
}

output "argocd_url" {
  description = "URL to access the ArgoCD UI"
  value       = "https://${module.argocd.external_ip}"
}
