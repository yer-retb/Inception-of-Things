apt-get update
apt-get upgrade -y
sudo systemctl stop ufw

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --server https://192.168.56.110:6443 --node-ip 192.168.56.111 --token hakkache02" sh -s -



