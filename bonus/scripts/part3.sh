#!/bin/bash

print_status "Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml || print_error "Failed to install ArgoCD"

print_status "Waiting for ArgoCD pods to be ready..."
kubectl wait --namespace argocd --for=condition=ready pod --selector=app.kubernetes.io/name=argocd-server --timeout=300s || print_error "ArgoCD pods did not become ready in time"

print_status "ArgoCD Initial Admin Password:"
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode
echo

if [ ! -f "../confs/argocd.yaml" ]; then
    print_error "argocd.yaml not found in ../confs/"
fi


print_status "Applying updated ArgoCD configuration..."
kubectl apply -f ../confs/argocd.yaml || print_error "Failed to apply updated argocd.yaml"

print_status "Starting port forwarding for ArgoCD..."
print_status "Access ArgoCD UI at http://localhost:8080"
print_status "Username: admin"
print_status "Use the password shown above to log in"
kubectl port-forward svc/argocd-server -n argocd 8080:80 || print_error "Failed to start port forwarding for ArgoCD"

print_status "Creating GitLab repository secret for ArgoCD..."

kubectl create secret generic gitlab-repo-https -n argocd \
    --from-literal=username=root \
    --from-literal=password="glpat-xhzonFh6aE_Ujk24atzW" \
    --from-literal=url=http://$MASTER_IP:31827/root/yassine.git || print_error "Failed to create GitLab repository secret for ArgoCD"

print_status "Part 3: ArgoCD installation and configuration completed successfully!"