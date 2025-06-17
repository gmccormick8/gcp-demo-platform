# CI/CD Workflow Approval Process

## Enhanced Approval Process

The enhanced workflow has been designed to automatically determine when a Terraform deployment requires manual approval:

1. **Automatic Change Detection**
   - The workflow automatically detects if there are changes in the Terraform plan
   - If there are no changes, the workflow bypasses the manual approval step
   - If changes are detected, the workflow requires manual approval before applying

2. **Notification Process**
   - When changes are detected, team members listed in the `APPROVERS` secret are notified
   - A summary of planned changes is provided in the notification
   - The full plan is available as a downloadable artifact in the GitHub Actions workflow

3. **Environment-Specific GitOps**
   - The ArgoCD deployment is automatically pointed to the appropriate GitOps repository branch
   - Each environment (dev, staging, prod) uses a matching branch name in the GitOps repository
   - This ensures that ArgoCD applies the correct configuration for each environment

## Configuring the Approval Process

1. **Set Up APPROVERS Secret**
   - Add a repository or environment secret called `APPROVERS`
   - Value should be a comma-separated list of GitHub usernames
   - For example: `user1,user2,user3`

2. **Environment Protection Rules**
   - For staging and production environments, enable protection rules in GitHub
   - Require review from your organization's owners or administrators
   - Set appropriate waiting periods if needed

## Workflow Behavior

- **No Changes Detected**:
  - The workflow will run validation and verification steps
  - It will then skip the manual approval job
  - The apply job will run but will not make any changes
  
- **Changes Detected**:
  - The workflow will pause at the manual approval step
  - Designated approvers will be notified
  - The workflow continues only after approval is granted
  - Changes are then applied to the environment
