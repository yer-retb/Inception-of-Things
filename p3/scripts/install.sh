#!/bin/bash


GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[+] $1${NC}"
}

print_error() {
    echo -e "${RED}[-] Error: $1${NC}"
    exit 1
}

check_status() {
    if [ $? -ne 0 ]; then
        print_error "$1 failed"
    fi
}

if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root (use sudo)"
fi

print_status "Updating system packages..."
apt-get update && apt-get upgrade -y || print_error "Failed to update system packages"

print_status "Installing prerequisites..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release || print_error "Failed to install prerequisites"

print_status "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io || print_error "Failed to install Docker"

usermod -aG docker $SUDO_USER

print_status "Installing k3d..."
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash || print_error "Failed to install k3d"

print_status "Docker version:"
docker --version
print_status "k3d version:"
k3d --version

print_status "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/ || print_error "Failed to install kubectl"

print_status "Creating k3d cluster..."
k3d cluster create mycluster --servers 1 --agents 1 || print_error "Failed to create k3d cluster"

print_status "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=60s
check_status "Cluster readiness"

print_status "Creating namespaces..."
kubectl create namespace dev || print_error "Failed to create dev namespace"
kubectl create namespace argocd || print_error "Failed to create argocd namespace"

if [ ! -f "../confs/myapp.yaml" ]; then
    print_error "myapp.yaml not found in ../confs/"
fi

if [ ! -f "../confs/git-ssh-key.yaml" ]; then
    print_error "git-ssh-key.yaml not found in ../confs/"
fi


print_status "Applying configurations..."
kubectl apply -f ../confs/myapp.yaml -n dev || print_error "Failed to apply myapp.yaml"

print_status "Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml || print_error "Failed to install ArgoCD"
kubectl apply -f ../confs/git-ssh-key.yaml || print_error "Failed to apply git-ssh-key.yaml"

kubectl apply -f ../confs/argocd.yaml || print_error "Failed to apply argocd.yaml"


print_status "Waiting for ArgoCD pods to be ready..."
kubectl wait --namespace argocd --for=condition=ready pod --selector=app.kubernetes.io/name=argocd-server --timeout=300s
check_status "ArgoCD readiness"

print_status "ArgoCD Initial Admin Password:"
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode

print_status "Starting port forwarding for ArgoCD..."
print_status "Access ArgoCD UI at http://localhost:8080"
print_status "Username: admin"
print_status "Use the password shown above to log in"
print_status "Use Ctrl+C to stop port forwarding"

kubectl port-forward svc/argocd-server -n argocd 8080:80

print_status "Script completed successfully!"