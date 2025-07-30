%{ for name, cluster in clusters ~}
  mario-${name}:
    name: mario-${name}
    namespace: ${namespace}
    project: default
    source:
      repoURL: ${gitops_repo_url}
      targetRevision: ${environment}
      path: helm/mario
      helm:
        values: |
          gateway:
            enable: ${name == "central" ? true : false}
          global:
            environment: ${environment}
    destination:
      server: https://${cluster.endpoint}
      namespace: ${app_namespace}
    syncPolicy:
      automated:
        prune: true
        selfHeal: true
      syncOptions:
        - CreateNamespace=true
    finalizers:
      - resources-finalizer.argocd.argoproj.io
%{ endfor ~}