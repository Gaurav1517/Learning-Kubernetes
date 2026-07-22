#!/usr/bin/env bash
set -euo pipefail

#############################################
# Kubernetes Worker Node Installer
# Ubuntu 22.04 / 24.04
# Kubernetes v1.34
#############################################

K8S_VERSION="v1.34"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

if [[ $EUID -ne 0 ]]; then
    error "Please run as root."
    exit 1
fi

############################################################

read -rp "Enter Worker Hostname : " WORKER_NAME

read -rp "Enter Control Plane IP/FQDN : " CONTROL_PLANE

read -rp "Enter Join Token : " JOIN_TOKEN

read -rp "Enter Discovery Token Hash : " DISCOVERY_HASH

############################################################

log "Setting hostname"

hostnamectl set-hostname "${WORKER_NAME}"

############################################################

SERVER_IP=$(hostname -I | awk '{print $1}')

grep -q "${WORKER_NAME}" /etc/hosts || cat >> /etc/hosts <<EOF

127.0.0.1 localhost
${SERVER_IP} ${WORKER_NAME}
EOF

############################################################

log "Disabling Swap"

swapoff -a

sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab

############################################################

log "Loading Kernel Modules"

cat >/etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

############################################################

log "Applying Sysctl"

cat >/etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF

sysctl --system

############################################################

log "Installing Dependencies"

apt update

apt install -y \
apt-transport-https \
ca-certificates \
curl \
gnupg \
lsb-release

############################################################

log "Installing containerd"

mkdir -p /etc/apt/keyrings

if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi

cat >/etc/apt/sources.list.d/docker.list <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable
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

############################################################

log "Installing Kubernetes"

mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key | \
gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

cat >/etc/apt/sources.list.d/kubernetes.list <<EOF
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /
EOF

apt update

apt install -y kubelet kubeadm kubectl

apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet

############################################################

log "Joining Cluster"

kubeadm join ${CONTROL_PLANE}:6443 \
--token ${JOIN_TOKEN} \
--discovery-token-ca-cert-hash ${DISCOVERY_HASH}

############################################################

echo
echo "=========================================="
echo " Worker Successfully Joined Cluster"
echo "=========================================="

echo

echo "Hostname : ${WORKER_NAME}"

echo "Control Plane : ${CONTROL_PLANE}"

echo

echo "Verify from Control Plane:"

echo "kubectl get nodes -o wide"
