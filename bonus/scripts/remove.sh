#!/bin/bash

echo "Starting removal of k3d, Docker, and kubectl..."

# Remove k3d
echo "Removing k3d..."
if command -v k3d &> /dev/null; then
  sudo rm -f /usr/local/bin/k3d
  echo "k3d removed."
else
  echo "k3d is not installed."
fi

# Remove Docker
echo "Removing Docker..."
if command -v docker &> /dev/null; then
  sudo systemctl stop docker
  sudo systemctl disable docker
  sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo rm -rf /var/lib/docker
  sudo rm -rf /var/lib/containerd
  echo "Docker removed."
else
  echo "Docker is not installed."
fi

# Remove kubectl
echo "Removing kubectl..."
if command -v kubectl &> /dev/null; then
  sudo rm -f /usr/local/bin/kubectl
  rm -rf ~/.kube
  echo "kubectl removed."
else
  echo "kubectl is not installed."
fi

# Clean up residual files
echo "Cleaning up residual files..."
sudo apt-get autoremove -y
sudo apt-get autoclean -y

echo "All tools removed successfully!"