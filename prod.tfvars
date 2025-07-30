environment = "prod"

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

clusters = {
  east = {
    cluster_name          = "east-cluster"
    region                = "us-east5"
    zone                  = "us-east5-c"
    subnet_key            = "demo-east-vpc"
    pods_network_name     = "demo-east-pods"
    services_network_name = "demo-east-services"
    master_ipv4_cidr      = "172.16.0.0/28"
  }
  central = {
    cluster_name          = "central-cluster"
    region                = "us-central1"
    zone                  = "us-central1-c"
    subnet_key            = "demo-central-vpc"
    pods_network_name     = "demo-central-pods"
    services_network_name = "demo-central-services"
    master_ipv4_cidr      = "172.16.1.0/28"
  }
  west = {
    cluster_name          = "west-cluster"
    region                = "us-west4"
    zone                  = "us-west4-c"
    subnet_key            = "demo-west-vpc"
    pods_network_name     = "demo-west-pods"
    services_network_name = "demo-west-services"
    master_ipv4_cidr      = "172.16.2.0/28"
  }
}

min_node_count = 1

max_node_count = 3

machine_type = "e2-standard-2"

disk_size_gb = 25

disk_type = "pd-standard"

gcp_sa_name = "argocd-gcp-sa"

k8s_sa_name = "argocd-k8s-sa"

namespace = "argocd"
