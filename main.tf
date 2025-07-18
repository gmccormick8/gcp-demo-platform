locals {
  clusters = {
    east = {
      # GKE cluster config
      cluster_name          = "east-cluster"
      region                = "us-east5"
      zone                  = "us-east5-c"
      subnet_key            = "demo-east-vpc"
      pods_network_name     = "demo-east-pods"
      services_network_name = "demo-east-services"
      master_ipv4_cidr      = "172.16.0.0/28"
    }
    central = {
      # GKE cluster config
      cluster_name          = "central-cluster"
      region                = "us-central1"
      zone                  = "us-central1-c"
      subnet_key            = "demo-central-vpc"
      pods_network_name     = "demo-central-pods"
      services_network_name = "demo-central-services"
      master_ipv4_cidr      = "172.16.1.0/28"
    }
    west = {
      # GKE cluster config
      cluster_name          = "west-cluster"
      region                = "us-west4"
      zone                  = "us-west4-c"
      subnet_key            = "demo-west-vpc"
      pods_network_name     = "demo-west-pods"
      services_network_name = "demo-west-services"
      master_ipv4_cidr      = "172.16.2.0/28"
    }
  }
}

# Create a VPC network and subnets
module "demo-vpc" {
  source       = "./modules/network"
  project_id   = var.project_id
  network_name = "demo"

  subnets = {
    "demo-east-vpc" = {
      region = "us-east5"
      cidr   = "10.0.0.0/24"
      secondary_ranges = {
        "demo-east-pods" = {
          ip_cidr_range = "192.168.0.0/19"
        }
        "demo-east-services" = {
          ip_cidr_range = "192.168.32.0/19"
        }
      }
    }
    "demo-central-vpc" = {
      region = "us-central1"
      cidr   = "10.0.1.0/24"
      secondary_ranges = {
        "demo-central-pods" = {
          ip_cidr_range = "192.168.64.0/19"
        }
        "demo-central-services" = {
          ip_cidr_range = "192.168.96.0/19"
        }
      }
    }
    "demo-west-vpc" = {
      region = "us-west4"
      cidr   = "10.0.2.0/24"
      secondary_ranges = {
        "demo-west-pods" = {
          ip_cidr_range = "192.168.128.0/19"
        }
        "demo-west-services" = {
          ip_cidr_range = "192.168.160.0/19"
        }
      }
    }
  }

  cloud_nat_configs = ["us-east5", "us-central1", "us-west4"]
}

module "gke_clusters" {
  for_each = local.clusters
  source   = "./modules/gke"

  project_id                 = var.project_id
  cluster_name               = each.value.cluster_name
  zone                       = each.value.zone
  network_name               = module.demo-vpc.network_self_link
  subnet_name                = module.demo-vpc.subnets[each.value.subnet_key].self_link
  pods_network_name          = each.value.pods_network_name
  services_network_name      = each.value.services_network_name
  master_ipv4_cidr_block     = each.value.master_ipv4_cidr
  min_node_count             = 1
  master_authorized_networks = [{ "cidr_block" : "0.0.0.0/0", "display_name" : "All IPs - For GitHub Actions" }]
  max_node_count             = 3
  machine_type               = "e2-small"
  disk_size_gb               = 25
  disk_type                  = "pd-standard"

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
    module.gke_clusters,
    terraform_data.fleet_membership_cleanup
  ]
}


# Register clusters with GKE Hub and enable Multi-Cluster Ingress (MCI)
resource "google_gke_hub_feature" "mci" {
  name     = "multiclusteringress"
  project  = var.project_id
  location = "global"

  spec {
    multiclusteringress {
      config_membership = "projects/${var.project_id}/locations/${local.clusters["central"].region}/memberships/${module.gke_clusters["central"].cluster_name}"
    }
  }

  depends_on = [
    module.gke_clusters,
    terraform_data.fleet_membership_cleanup
  ]
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
        gcloud container clusters update "$${CLUSTER}-cluster" \
          --project=${self.triggers_replace.project_id} \
          --location=$(gcloud container clusters list --project=${self.triggers_replace.project_id} --filter="name=$${CLUSTER}-cluster" --format="value(location)") \
          --unregister-fleet \
          --quiet || true
      done

      # Wait for unregistration to complete
      echo "Waiting 90 seconds for fleet unregistration to complete..."
      sleep 90
    EOT
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }

  depends_on = [google_gke_hub_feature.mci, google_gke_hub_feature.mcs]
}

resource "kubernetes_namespace" "mario" {
  metadata {
    name = "mario"
  }

  depends_on = [kubernetes_namespace.argocd]
}

module "argocd_central" {
  source      = "./modules/argocd"
  project_id  = var.project_id
  gcp_sa_name = "argocd-central-gcp-sa"
  k8s_sa_name = "argocd-central-k8s-sa"
  namespace   = kubernetes_namespace.argocd.metadata[0].name
  environment = var.environment
  gitops_repo_url = "https://github.com/gmccormick8/gcp-demo-app.git"

  central_cluster_endpoint       = module.gke_clusters["central"].cluster_endpoint
  central_cluster_ca_certificate = module.gke_clusters["central"].master_auth.cluster_ca_certificate
  central_access_token           = data.google_client_config.default.access_token
  central_region                 = local.clusters["central"].region

  east_cluster_endpoint       = module.gke_clusters["east"].cluster_endpoint
  east_cluster_ca_certificate = module.gke_clusters["east"].master_auth.cluster_ca_certificate
  east_access_token           = data.google_client_config.default.access_token
  east_region                 = local.clusters["east"].region

  west_cluster_endpoint       = module.gke_clusters["west"].cluster_endpoint
  west_cluster_ca_certificate = module.gke_clusters["west"].master_auth.cluster_ca_certificate
  west_access_token           = data.google_client_config.default.access_token
  west_region                 = local.clusters["west"].region
}
