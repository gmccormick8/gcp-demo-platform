module "argocd" {
  source = "squareops/argocd/kubernetes"
  argocd_config = {
    hostname                     = "argocd.prod.in"
    values_yaml                  = file("${path.module}/helm/values.yaml")
    argocd_notifications_enabled = false
    autoscaling_enabled          = false
    ingress_class_name           = "loadbalancer"
    redis_ha_enabled             = false
    slack_notification_token     = ""
  }
}
