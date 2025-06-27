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

      # ArgoCD cluster config
      control_cluster = false
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

      # ArgoCD cluster config
      control_cluster = true
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

      # ArgoCD cluster config
      control_cluster = false
    }
  }

  # ArgoCD default applications based on environment
  argocd_apps = {
    "core-apps" = {
      name            = "core-apps"
      project         = "default"
      repo_url        = var.gitops_repo_url
      target_revision = var.environment
      path            = "charts/core"
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "core"
      }
      sync_policy = {
        automated = {
          prune       = true
          self_heal   = true
          allow_empty = false
        }
        sync_options = ["CreateNamespace=true"]
      }
    }

    "demo-app" = {
      name            = "demo-app"
      project         = "default"
      repo_url        = var.gitops_repo_url
      target_revision = var.environment
      path            = "charts/demo-app"
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "demo"
      }
      sync_policy = {
        automated = {
          prune       = true
          self_heal   = true
          allow_empty = false
        }
        sync_options = ["CreateNamespace=true"]
      }
    }
  }
}

# Create a VPC network and subnets
module "demo-vpc" {
  source       = "./modules/network"
  project_id   = var.project_id
  network_name = "demo"

  # Add firewall rule for ArgoCD
  firewall_rules = {
    "allow-argocd-external" = {
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = ["0.0.0.0/0"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["80", "443", "8080"]
        }
      ]
    }
  }

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
  master_authorized_networks = var.master_authorized_networks
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

# Create a global static IP address for ArgoCD ingress
resource "google_compute_global_address" "argocd_ip" {
  name         = "argocd-global-ip"
  project      = var.project_id
  description  = "Global static IP address for ArgoCD ingress"
  address_type = "EXTERNAL"
}

# No managed certificate needed since we're using IP-based access

# Install and configure ArgoCD in the central cluster after MCI is set up
module "argocd" {
  source = "./modules/argocd"

  namespace                = "argocd"
  admin_password_secret_id = var.argocd_secret_name
  environment              = var.environment
  gitops_repo_url          = var.gitops_repo_url

  # Enable ingress for external access with public IP
  ingress_enabled = true
  ingress_host    = "" # Using IP-based access
  ingress_annotations = {
    "kubernetes.io/ingress.class" : "gce"
    "kubernetes.io/ingress.global-static-ip-name" : google_compute_global_address.argocd_ip.name
    "kubernetes.io/ingress.allow-http" : "true"
  }

  # Configure HA mode for production environments
  ha_enabled = var.environment == "prod" ? true : false

  # Set service type to NodePort for GKE Ingress compatibility with IP-based access
  server_service_type = "NodePort"

  # Use simple insecure setup for direct IP access
  server_insecure = true

  # Create ArgoCD projects
  argocd_projects = {
    default = {
      name        = "default"
      description = "Default Project"
      source_repos = [
        var.gitops_repo_url
      ]
      destinations = [
        {
          server    = "https://kubernetes.default.svc"
          namespace = "*"
        }
      ]
    }
  }

  # Create ArgoCD applications from local configuration
  argocd_applications = local.argocd_apps
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
