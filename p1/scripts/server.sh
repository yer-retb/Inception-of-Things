#!/bin/bash
set -e

echo "🔧 Updating system..."
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y curl

echo "🚀 Installing K3s server..."
curl -sfL https://get.k3s.io | sh -

echo "📁 Exporting KUBECONFIG..."
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

sudo cp /etc/rancher/k3s/k3s.yaml /home/vagrant/k3s.yaml
sudo chown vagrant:vagrant /home/vagrant/k3s.yaml
echo 'export KUBECONFIG=~/k3s.yaml' >> /home/vagrant/.bashrc

echo "🔐 Saving K3s node token for workers to use..."
sudo mkdir -p /vagrant/confs
sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/confs/token

echo "✅ K3s server installation complete!"
