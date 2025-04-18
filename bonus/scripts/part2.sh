#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}[+] $1${NC}"
}

print_status "Applying configurations..."
kubectl apply -f ../confs/myapp.yaml -n dev || print_error "Failed to apply myapp.yaml"

# Get the master node IP address
MASTER_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
if [ -z "$MASTER_IP" ]; then
    print_error "Failed to retrieve the master node IP address"
fi
print_status "Using Master IP: $MASTER_IP"

# Install Helm if not already installed
if ! command -v helm &> /dev/null; then
    print_status "Helm is not installed. Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash || print_error "Failed to install Helm"
else
    print_status "Helm is already installed"
fi

# Add GitLab Helm repository
helm repo add gitlab https://charts.gitlab.io/ || print_error "Failed to add GitLab Helm repository"
helm repo update || print_error "Failed to update Helm repositories"

# Create GitLab namespace
kubectl create namespace gitlab || print_status "Namespace 'gitlab' already exists"

# Download GitLab values file
curl -fsSL -o values-minikube-minimum.yaml https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml || print_error "Failed to download GitLab values file"

# Update values file with the master node IP
sed -i "s/192.168.99.100.nip.io/$MASTER_IP.nip.io/g" values-minikube-minimum.yaml
sed -i "s/192.168.99.100/$MASTER_IP/g" values-minikube-minimum.yaml

# Install GitLab using Helm
print_status "Installing GitLab..."
helm install gitlab gitlab/gitlab --namespace gitlab \
    --set global.edition=ce \
    --set global.hosts.externalIP=$MASTER_IP \
    --set global.hosts.https=false \
    -f values-minikube-minimum.yaml || print_error "Failed to install GitLab"

# Wait for GitLab webservice to be ready
print_status "Waiting for GitLab webservice to be ready..."
kubectl wait --for=condition=ready pod -l app=webservice -n gitlab --timeout=s || print_error "GitLab webservice did not become ready in time"

# Clean up values file
rm -rf values-minikube-minimum.yaml


# Expose GitLab webservice as a NodePort
print_status "Exposing GitLab webservice as a NodePort..."

# Display GitLab credentials
print_status "GitLab Credentials:"
echo "Username: root"
echo "Password: $(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 --decode)"

print_status "Part 2: GitLab installation completed successfully!"

