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

output "argocd_url" {
  description = "URL to access ArgoCD UI"
  value       = "http://${google_compute_global_address.argocd_ip.address}"
}

output "argocd_ip_address" {
  description = "Public IP address for ArgoCD ingress"
  value       = google_compute_global_address.argocd_ip.address
}

output "argocd_admin_username" {
  description = "The ArgoCD admin username"
  value       = module.argocd.argocd_admin_username
}

output "argocd_deployed_applications" {
  description = "List of deployed ArgoCD applications"
  value       = module.argocd.application_names
}

output "argocd_deployed_projects" {
  description = "List of deployed ArgoCD projects"
  value       = module.argocd.project_names
}

output "argocd_access_instructions" {
  description = "Instructions to access ArgoCD"
  value       = <<EOT
To access ArgoCD:

1. Navigate to: http://${google_compute_global_address.argocd_ip.address}

3. Login credentials:
   - Username: ${module.argocd.argocd_admin_username}
   - Password: Retrieve from Secret Manager: ${var.argocd_secret_name}
   
   To retrieve the password using gcloud:
   $ gcloud secrets versions access latest --secret=${var.argocd_secret_name} --project=${var.project_id}
EOT
}
