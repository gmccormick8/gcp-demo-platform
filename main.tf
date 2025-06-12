# Create a VPC network and subnets
module "demo-vpc" {
  source                          = "./modules/network"
  project_id                      = var.project_id
  network_name                    = "demo"
  delete_default_routes_on_create = false

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
