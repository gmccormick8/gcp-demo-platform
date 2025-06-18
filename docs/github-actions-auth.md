# GitHub Actions Authentication with Workload Identity Federation

This guide explains how to configure and troubleshoot GitHub Actions authentication with Google Cloud's Workload Identity Federation.

## Branch-Specific Security Configuration

Our platform uses enhanced security with Workload Identity Federation to ensure that GitHub Actions can only access resources when running from:

1. The correct repository (`gmccormick8/gcp-demo-platform`)
2. The designated branch (dev, staging, or prod respectively)

This provides strong security isolation between environments and prevents unauthorized access.

## Understanding the Authentication Mechanism

The Workload Identity Provider configuration uses attribute conditions to verify:

1. **Repository**: Checks that the GitHub token comes from our repository
2. **Branch**: Verifies that the action is running on the correct branch for the environment
3. **OIDC Token**: Uses OpenID Connect for secure authentication without storing service account keys

### Attribute Conditions

The attribute condition we use looks like:

```
attribute.repository=='gmccormick8/gcp-demo-platform' && (attribute.branch.startsWith('refs/heads/dev') || attribute.branch.endsWith('dev'))
```

This ensures that only workflows running on the appropriate branch in our repository can authenticate.

## Troubleshooting Authentication Errors

If you encounter errors like:

```
google-github-actions/auth failed with: failed to generate Google Cloud federated token: 
{"error":"unauthorized_client","error_description":"The given credential is rejected by the attribute condition."}
```

This indicates that the GitHub token provided doesn't match the attribute conditions set in your Workload Identity Provider.

### Common Causes:

1. Running a workflow on a branch that doesn't match the environment
2. Pull request from a fork (which has a different repository attribute)
3. Incorrect GitHub repository or environment configuration

### Fixing Authentication Issues

Use the provided fix scripts to update the Workload Identity Provider configuration:

#### Linux/macOS:
```bash
./fix-workload-identity.sh <branch>  # where <branch> is dev, staging, or prod
```

#### Windows:
```powershell
.\fix-workload-identity.ps1 -Branch <branch>
```

These scripts will ensure that the authentication is properly configured to allow access only from the correct branch in the repository.

## Security Benefits

This strict authentication model provides several security benefits:

1. **Environment Isolation**: Each environment (dev, staging, prod) has its own service account with appropriate permissions
2. **Branch Protection**: Changes can only be deployed from the designated branch for each environment
3. **Zero Long-lived Credentials**: No service account keys are stored in GitHub or anywhere else
4. **Least Privilege**: Service accounts have only the permissions needed for their specific environment

## Additional Resources

- [GitHub Actions OIDC Token Format](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [GCP Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
