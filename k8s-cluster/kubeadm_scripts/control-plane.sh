#!/usr/bin/env bash
set -euo pipefail

#############################################
# Kubernetes Single Node Installation Script
# Ubuntu 22.04 / 24.04
# Kubernetes v1.34
#############################################

K8S_VERSION="v1.34"
POD_CIDR="192.168.0.0/16"
HOSTNAME="control-plane"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

if [[ $EUID -ne 0 ]]; then
    error "Run this script as root."
    exit 1
fi

SERVER_IP=$(hostname -I | awk '{print $1}')

########################################################

log "Setting hostname"

hostnamectl set-hostname ${HOSTNAME}

########################################################

log "Updating /etc/hosts"

grep -q "${HOSTNAME}" /etc/hosts || cat >> /etc/hosts <<EOF

127.0.0.1 localhost
${SERVER_IP} ${HOSTNAME}
EOF

########################################################

log "Disabling swap"

swapoff -a
sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab

########################################################

log "Loading kernel modules"

cat >/etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

########################################################

log "Applying sysctl"

cat >/etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF

sysctl --system

########################################################

log "Installing dependencies"

apt update

apt install -y \
apt-transport-https \
ca-certificates \
curl \
gnupg \
lsb-release

########################################################

log "Installing containerd"

mkdir -p /etc/apt/keyrings

if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi

cat >/etc/apt/sources.list.d/docker.list <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable
EOF

apt update

apt install -y containerd.io

mkdir -p /etc/containerd

containerd config default >/etc/containerd/config.toml

sed -i \
's/SystemdCgroup = false/SystemdCgroup = true/' \
/etc/containerd/config.toml

systemctl daemon-reload
systemctl enable containerd
systemctl restart containerd

########################################################

log "Installing Kubernetes"

mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key | \
gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

cat >/etc/apt/sources.list.d/kubernetes.list <<EOF
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /
EOF

apt update

apt install -y \
kubelet \
kubeadm \
kubectl

apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet

########################################################

if [ ! -f /etc/kubernetes/admin.conf ]; then

log "Initializing Kubernetes Cluster"

kubeadm init \
--pod-network-cidr=${POD_CIDR}

fi

########################################################

log "Configuring kubectl"

mkdir -p /root/.kube

cp /etc/kubernetes/admin.conf /root/.kube/config

export KUBECONFIG=/root/.kube/config

########################################################

log "Waiting for API Server"

until kubectl get nodes >/dev/null 2>&1
do
    sleep 5
done

########################################################

log "Installing Calico"

kubectl apply -f \
https://raw.githubusercontent.com/projectcalico/calico/v3.30.3/manifests/calico.yaml

########################################################

log "Removing Control Plane Taint"

kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

########################################################

log "Waiting for Calico"

kubectl wait \
--for=condition=Ready \
pod \
--all \
-n kube-system \
--timeout=600s || true

########################################################

echo
echo "==========================================="
echo " Kubernetes Installation Completed"
echo "==========================================="
echo

kubectl cluster-info

echo

kubectl get nodes -o wide

echo

kubectl get pods -A

echo

echo "Server IP : ${SERVER_IP}"

echo

echo "You can start deploying workloads now."
