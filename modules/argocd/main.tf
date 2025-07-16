resource "google_compute_address" "argocd_ip" {
  name   = "argocd-public-ip"
  region = var.region
}

module "argocd" {
  source = "squareops/argocd/kubernetes"
  argocd_config = {
    hostname                     = google_compute_address.argocd_ip.address
    values_yaml                  = file("${path.module}/helm/values.yaml")
    argocd_notifications_enabled = false
    autoscaling_enabled          = false
    ingress_class_name           = "nginx"
    redis_ha_enabled             = false
    slack_notification_token     = ""
  }
}
