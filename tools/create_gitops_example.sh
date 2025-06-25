#!/bin/bash
# Script to create a simple example application in a GitOps repository
# Usage: ./create_gitops_example.sh <repository_url> <branch>

set -e

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <repository_url> <branch>"
    echo "Example: $0 https://github.com/user/repo.git main"
    exit 1
fi

REPO_URL=$1
BRANCH=$2
TEMP_DIR=$(mktemp -d)

echo "Cloning repository $REPO_URL branch $BRANCH..."
git clone --branch "$BRANCH" "$REPO_URL" "$TEMP_DIR" || {
    echo "Failed to clone repository. Checking if we need to create the branch..."
    git clone "$REPO_URL" "$TEMP_DIR"
    cd "$TEMP_DIR"
    git checkout -b "$BRANCH"
}

cd "$TEMP_DIR"

# Create basic directory structure
mkdir -p cluster-resources
mkdir -p applications

# Create a basic namespace
cat > cluster-resources/namespace.yaml <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: demo
EOF

# Create a demo application
cat > applications/demo-app.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: demo
  template:
    metadata:
      labels:
        app: demo
    spec:
      containers:
      - name: demo
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: demo-app
  namespace: demo
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: demo
EOF

# Create a root kustomization file to include all resources
cat > kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- cluster-resources/namespace.yaml
- applications/demo-app.yaml
EOF

# Commit and push changes
git add .
git config --global user.email "gitops@example.com"
git config --global user.name "GitOps Example Creator"
git commit -m "Add example GitOps resources"
git push origin "$BRANCH" || {
    echo "Failed to push directly. Trying to set upstream..."
    git push --set-upstream origin "$BRANCH"
}

echo "Example GitOps resources created successfully!"
echo "ArgoCD should now be able to sync from: $REPO_URL with branch: $BRANCH"

# Cleanup
rm -rf "$TEMP_DIR"
