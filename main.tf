terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  backend "gcs" {}
}

provider "google" {
  project = var.project_id
}


variable "environment" {
  default = "prod"
}

locals {
  service_account_id = "github-actions-sa-${var.environment}"
}

# Grant additional roles to the GitHub Actions service account
resource "google_project_iam_member" "github_actions_roles" {
  for_each = toset([
    "roles/monitoring.admin",
    "roles/logging.admin"
  ])

  project = "hazel-delight-462019-i6"

  role   = each.key
  member = "serviceAccount:${local.service_account_id}@hazel-delight-462019-i6.iam.gserviceaccount.com"
}
