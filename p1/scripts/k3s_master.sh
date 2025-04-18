apt-get update
apt-get upgrade -y
sudo systemctl stop ufw

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip 192.168.56.110 --write-kubeconfig-mode 0644 --token hakkache02" sh -s -

sleep 90