output "argocd_release" {
  value       = helm_release.argocd
  description = "ArgoCD Helm release info"
}

output "applicationset_status" {
  description = "Status of the ApplicationSet deployment"
  value = {
    name      = "demo-applicationset"
    namespace = var.namespace
    revision  = helm_release.mario_applicationset.revision
  }
}

# Add commands for manual verification
output "debug_commands" {
  description = "Commands for debugging ApplicationSet deployment"
  value       = <<EOT
    # Check ApplicationSet status
    kubectl get applicationset -n ${var.namespace} demo-applicationset -o yaml

    # Check Application status
    kubectl get applications -n ${var.namespace}

    # Check ArgoCD logs
    kubectl logs -n ${var.namespace} -l app.kubernetes.io/name=argocd-applicationset-controller

    # Check if repo is registered
    kubectl get secret -n ${var.namespace} -l argocd.argoproj.io/secret-type=repository
  EOT
}
