applications:
  mario-east:
    name: mario-east
    namespace: ${app_namespace}
    project: default
    source:
      repoURL: ${gitops_repo_url}
      targetRevision: ${environment}
      path: helm/mario
      helm:
        values: |
          gateway:
            enable: false
          global:
            environment: ${environment}
    destination:
      server: https://${east_cluster_endpoint}
      namespace: ${app_namespace}
    syncPolicy:
      automated:
        prune: true
        selfHeal: true
      syncOptions:
        - CreateNamespace=false

  mario-central:
    name: mario-central
    namespace: ${app_namespace}
    project: default
    source:
      repoURL: ${gitops_repo_url}
      targetRevision: ${environment}
      path: helm/mario
      helm:
        values: |
          gateway:
            enable: true
          global:
            environment: ${environment}
    destination:
      server: https://${central_cluster_endpoint}
      namespace: ${app_namespace}
    syncPolicy:
      automated:
        prune: true
        selfHeal: true
      syncOptions:
        - CreateNamespace=false

  mario-west:
    name: mario-west
    namespace: ${app_namespace}
    project: default
    source:
      repoURL: ${gitops_repo_url}
      targetRevision: ${environment}
      path: helm/mario
      helm:
        values: |
          gateway:
            enable: false
          global:
            environment: ${environment}
    destination:
      server: https://${west_cluster_endpoint}
      namespace: ${app_namespace}
    syncPolicy:
      automated:
        prune: true
        selfHeal: true
      syncOptions:
        - CreateNamespace=false
