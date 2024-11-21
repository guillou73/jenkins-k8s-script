#!/bin/bash
# Set hostname
hostnamectl set-hostname k8s-worker

# Update the system
apt-get update && apt-get upgrade -y

# Install necessary packages
apt-get install -y curl apt-transport-https ca-certificates gpg

# Disable swap
swapoff -a
sed -i '/swap/d' /etc/fstab

# Install containerd
apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# Configure kernel modules
cat <<EOF > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Configure sysctl parameters
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

# Add Kubernetes repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' > /etc/apt/sources.list.d/kubernetes.list

# Install Kubernetes components
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Wait for the master node to be ready
sleep 180

# Join the cluster using the master node's join command
MASTER_IP="${master_ip}"
until nc -z $MASTER_IP 6443; do
    echo "Waiting for master node to be ready..."
    sleep 10
done

# Fetch and execute join command
scp -o StrictHostKeyChecking=no -i /home/ubuntu/.ssh/id_rsa ubuntu@$MASTER_IP:/$HOME/join-cluster.sh /$HOME/
bash /$HOME/join-cluster.sh