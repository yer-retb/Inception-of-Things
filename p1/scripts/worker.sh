#!/bin/bash
set -e

echo "🔧 Updating system..."
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y curl

echo "📥 Reading K3s token from shared folder..."
TOKEN=$(cat /vagrant/confs/token)

SERVER_IP="192.168.56.110"

echo "🚀 Installing K3s agent (worker node)..."
curl -sfL https://get.k3s.io | K3S_URL="https://${SERVER_IP}:6443" K3S_TOKEN="$TOKEN" sh -

echo "✅ K3s agent successfully joined the cluster!"
