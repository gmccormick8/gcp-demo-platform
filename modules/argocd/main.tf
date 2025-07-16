module "argocd" {
  source = "squareops/argocd/kubernetes"
  argocd_config = {
    hostname    = "argocd.prod.in"
    values_yaml = file("${path.module}/helm/values.yaml")
  }
}
