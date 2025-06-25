# ArgoCD Troubleshooting Guide

This document provides guidance on troubleshooting common ArgoCD issues in the GCP Demo Platform.

## Repository Connection Issues

If ArgoCD is installed but not connecting to your Git repository, check the following:

### 1. Verify Repository Exists

Ensure the repository URL specified in `variables.tf` exists and is accessible:

```hcl
variable "gitops_repo_url" {
  description = "URL of the Git repository containing ArgoCD configuration"
  type        = string
  default     = "https://github.com/gmccormick8/gcp-demo-app.git"
}
```

### 2. Check Repository Structure

The ArgoCD configuration expects to find Kubernetes manifests in the repository. By default, it looks in:

- Root directory (`.`) for the main application
- `cluster-resources` directory for cluster-wide resources

Ensure at least one of these exists in your repository.

### 3. Accessing ArgoCD UI

1. Get the external IP address:
   ```bash
   kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
   ```

2. Access the ArgoCD UI at `http://<EXTERNAL-IP>` or `https://<EXTERNAL-IP>`

3. Login with username `admin` and the password stored in GCP Secret Manager

### 4. Checking Application Status

Once logged in:
1. Check if any applications are listed
2. For each application, verify:
   - Status (Healthy/Unhealthy/OutOfSync)
   - Repository URL
   - Path within repository 
   - Sync status

### 5. Manual Repository Verification

You can manually check if the repository is accessible and contains the expected structure:

```bash
# Clone the repository
git clone https://github.com/gmccormick8/gcp-demo-app.git
cd gcp-demo-app

# Check for manifests in root directory
ls *.yaml *.yml

# Check for manifests in cluster-resources directory
ls cluster-resources/*.yaml cluster-resources/*.yml
```

### 6. Debug Repository Connection

If you need to debug repository connection issues from inside the ArgoCD pod:

```bash
# Get a pod name
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server

# Execute commands inside the pod
kubectl exec -it <pod-name> -n argocd -- bash

# Test repository connection
argocd repo list
argocd repo add <repo-url> --username <username> --password <password> # if needed
```

## Common Solutions

1. **Repository Structure**: Create a simple `application.yaml` in your repository's root with a basic Kubernetes Deployment
2. **Private Repository**: If using a private repository, set up credentials in ArgoCD
3. **Branch Issues**: Verify the branch specified in `gitops_repo_branch` exists in your repository
