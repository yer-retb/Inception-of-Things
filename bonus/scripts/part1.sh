#!/bin/bash

# Define colors for status messages
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}[+] $1${NC}"
}

# Function to print error messages and exit
print_error() {
    echo -e "${RED}[-] Error: $1${NC}"
    exit 1
}

# Function to check the status of the last command
check_status() {
    if [ $? -ne 0 ]; then
        print_error "$1 failed"
    fi
}

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root (use sudo)"
fi

# Update system packages
print_status "Updating system packages..."
apt-get update && apt-get upgrade -y || print_error "Failed to update system packages"

# Install prerequisites
print_status "Installing prerequisites..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release || print_error "Failed to install prerequisites"

# Install Docker
print_status "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io || print_error "Failed to install Docker"
usermod -aG docker $SUDO_USER

# Install k3d
print_status "Installing k3d..."
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash || print_error "Failed to install k3d"

# Verify Docker and k3d installation
print_status "Docker version: $(docker --version)"
print_status "k3d version: $(k3d --version)"

# Install kubectl
print_status "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/ || print_error "Failed to install kubectl"

# Create k3d cluster
print_status "Creating k3d cluster..."
k3d cluster create mycluster --servers 1 --agents 1 || print_error "Failed to create k3d cluster"

# Wait for cluster to be ready
print_status "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=60s || print_error "Cluster readiness check failed"

# Create namespaces
print_status "Creating namespaces..."
kubectl create namespace dev || print_status "Namespace 'dev' already exists"
kubectl create namespace argocd || print_status "Namespace 'argocd' already exists"

print_status "Part 1: System setup and prerequisites completed successfully!"