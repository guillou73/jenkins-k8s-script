#!/bin/bash
# Set hostname
hostnamectl set-hostname k8s-master

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

# Initialize Kubernetes cluster
kubeadm init --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors=NumCPU

# Set up kubeconfig
mkdir -p /$HOME/.kube
cp -i /etc/kubernetes/admin.conf /$HOME/.kube/config
chown $(id -u):$(id -g) /$HOME/.kube/config

# Install Calico networking
kubectl --kubeconfig=/$HOME/.kube/config apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml

# Generate join command and save it
kubeadm token create --print-join-command > /$HOME/join-command.txt

# Create a script that worker nodes can use to join the cluster
echo "#!/bin/bash" > /$HOME/join-cluster.sh
kubeadm token create --print-join-command >> /$HOME/join-cluster.sh
chmod +x /$HOME/join-cluster.sh
