# Create a VPC network and subnets
module "demo-vpc" {
  source       = "./modules/network"
  project_id   = var.project_id
  network_name = "demo"

  subnets = var.subnets

  cloud_nat_configs = [for cluster in var.clusters : cluster.region]
}

module "gke_clusters" {
  for_each = var.clusters
  source   = "./modules/gke"

  project_id             = var.project_id
  cluster_name           = each.value.cluster_name
  zone                   = each.value.zone
  network_name           = module.demo-vpc.network_self_link
  subnet_name            = module.demo-vpc.subnets[each.value.subnet_key].self_link
  pods_network_name      = each.value.pods_network_name
  services_network_name  = each.value.services_network_name
  master_ipv4_cidr_block = each.value.master_ipv4_cidr
  min_node_count         = var.min_node_count
  max_node_count         = var.max_node_count
  machine_type           = var.machine_type
  disk_size_gb           = var.disk_size_gb
  disk_type              = var.disk_type

  depends_on = [
    module.demo-vpc
  ]
}

# Configure GKE Hub and enable Multi-Cluster Services (MCS)
resource "google_gke_hub_feature" "mcs" {
  name     = "multiclusterservicediscovery"
  project  = var.project_id
  location = "global"

  depends_on = [
    module.gke_clusters
  ]
}


# Register clusters with GKE Hub and enable Multi-Cluster Ingress (MCI)
resource "google_gke_hub_feature" "mci" {
  name     = "multiclusteringress"
  project  = var.project_id
  location = "global"

  spec {
    multiclusteringress {
      config_membership = "projects/${var.project_id}/locations/${var.clusters["central"].region}/memberships/${module.gke_clusters["central"].cluster_name}"
    }
  }

  depends_on = [
    module.gke_clusters
  ]
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
  }
}

module "argocd_central" {
  source          = "./modules/argocd"
  project_id      = var.project_id
  gcp_sa_name     = var.gcp_sa_name
  k8s_sa_name     = var.k8s_sa_name
  namespace       = kubernetes_namespace.argocd.metadata[0].name
  environment     = var.environment
  gitops_repo_url = "https://github.com/gmccormick8/gcp-demo-app.git"

  clusters = {
    for k, v in var.clusters : k => {
      endpoint       = module.gke_clusters[k].cluster_endpoint
      ca_certificate = module.gke_clusters[k].master_auth.cluster_ca_certificate
      access_token   = data.google_client_config.default.access_token
    }
  }
}

# Cleanup dynamically created firewall rules for GKE clusters
resource "terraform_data" "gke_fw_cleanup" {
  triggers_replace = {
    project_id = var.project_id
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      RULES=$(gcloud compute firewall-rules list --project=${self.triggers_replace.project_id} --filter='name~^gke-.*mcsd$' --format='value(name)')
      if [ ! -z "$RULES" ]; then
        for RULE in $RULES; do
          echo "Deleting firewall rule: $RULE"
          gcloud compute firewall-rules delete $RULE --project=${self.triggers_replace.project_id} --quiet
        done
      else
        echo "No matching firewall rules found to delete"
      fi
    EOT
  }

  depends_on = [module.demo-vpc]
}

# Cleanup dynamically created fleet memberships
resource "terraform_data" "fleet_membership_cleanup" {
  triggers_replace = {
    project_id = var.project_id
  }
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      echo "Unregistering clusters from fleet..."
      for CLUSTER in central east west; do
        gcloud container fleet memberships delete "$${CLUSTER}-cluster" \
          --project=${self.triggers_replace.project_id} \
          --quiet || true
      done

      # Wait for unregistration to complete
      echo "Waiting 180 seconds for fleet unregistration to complete..."
      sleep 180

      echo "Checking for orphaned forwarding rules..."
      gcloud compute forwarding-rules list --filter="name~'mcs'" --format="value(name)" \
      | while read rule; do
        echo "Deleting $rule..."
        gcloud compute forwarding-rules delete "$rule" --global --quiet || true
      done
    EOT
  }

  depends_on = [
    module.gke_clusters,
    google_gke_hub_feature.mcs,
    google_gke_hub_feature.mci
  ]
}
