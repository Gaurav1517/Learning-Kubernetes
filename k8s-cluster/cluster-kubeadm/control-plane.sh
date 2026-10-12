#!/usr/bin/env bash
set -Eeuo pipefail

# Kubernetes control-plane installer
# Ubuntu 22.04 / 24.04
# Kubernetes v1.34 + containerd + Flannel VXLAN

K8S_VERSION="v1.34"
POD_CIDR="10.244.0.0/16"
HOSTNAME="k8s-control-plane"
CNI_PLUGINS_VERSION="v1.7.1"
FLANNEL_VERSION="v0.28.9"

log() { echo "[INFO] $*"; }
die() { echo "[ERROR] $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Run with sudo or as root."
command -v apt-get >/dev/null || die "This script requires Ubuntu/Debian."

# Avoid accidentally reinstalling an existing cluster.
[[ ! -f /etc/kubernetes/admin.conf ]] ||
  die "A Kubernetes control plane already exists. Use a fresh instance."

# Detect the EC2 private IPv4 address.
# You can override it by running: NODE_IP=172.31.x.x ./control-plane.sh
if [[ -z "${NODE_IP:-}" ]]; then
  TOKEN=$(curl -fsS --connect-timeout 2 --max-time 3 \
    -X PUT http://169.254.169.254/latest/api/token \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 60" 2>/dev/null || true)

  if [[ -n "$TOKEN" ]]; then
    NODE_IP=$(curl -fsS --connect-timeout 2 --max-time 3 \
      -H "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null || true)
  fi

  if [[ -z "${NODE_IP:-}" ]]; then
    NODE_IP=$(ip -4 route get 1.1.1.1 |
      awk '{for (i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}' || true)
  fi
fi

[[ -n "${NODE_IP:-}" ]] || die "Cannot detect private IP. Set NODE_IP manually."
ip -4 addr show | grep -qF "$NODE_IP" ||
  die "NODE_IP=$NODE_IP is not assigned to this instance."

log "Node IP: $NODE_IP"
log "Setting hostname: $HOSTNAME"
hostnamectl set-hostname "$HOSTNAME"

log "Disabling swap"
swapoff -a
sed -ri '/\sswap\s/s/^/#/' /etc/fstab

log "Loading kernel modules"
cat >/etc/modules-load.d/k8s.conf <<'EOF'
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

log "Applying sysctl settings"
cat >/etc/sysctl.d/k8s.conf <<'EOF'
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF
sysctl --system

log "Installing dependencies"
apt-get update
apt-get install -y ca-certificates curl gpg lsb-release tar

log "Installing containerd"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg |
  gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

ARCH=$(dpkg --print-architecture)
CODENAME=$( . /etc/os-release && echo "$VERSION_CODENAME" )

cat >/etc/apt/sources.list.d/docker.list <<EOF
deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable
EOF

apt-get update
apt-get install -y containerd.io
mkdir -p /etc/containerd
containerd config default >/etc/containerd/config.toml

# Align containerd and kubelet cgroup drivers.
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' \
  /etc/containerd/config.toml

systemctl enable --now containerd
systemctl restart containerd
systemctl is-active --quiet containerd ||
  die "containerd failed to start."

log "Installing standard CNI plugin binaries"
case "$(dpkg --print-architecture)" in
  amd64) CNI_ARCH="amd64" ;;
  arm64) CNI_ARCH="arm64" ;;
  *) die "Unsupported architecture: $(dpkg --print-architecture)" ;;
esac

mkdir -p /opt/cni/bin
curl -fL \
  "https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VERSION}/cni-plugins-linux-${CNI_ARCH}-${CNI_PLUGINS_VERSION}.tgz" |
  tar -xz -C /opt/cni/bin

log "Configuring Kubernetes repository"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key" |
  gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
chmod a+r /etc/apt/keyrings/kubernetes-apt-keyring.gpg

cat >/etc/apt/sources.list.d/kubernetes.list <<EOF
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /
EOF

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet

log "Initializing Kubernetes control plane"
kubeadm init \
  --apiserver-advertise-address="$NODE_IP" \
  --pod-network-cidr="$POD_CIDR" \
  --cri-socket=unix:///run/containerd/containerd.sock

log "Configuring kubectl for root"
mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config
chmod 600 /root/.kube/config
export KUBECONFIG=/etc/kubernetes/admin.conf

log "Installing Flannel VXLAN CNI"
curl -fL \
  "https://github.com/flannel-io/flannel/releases/download/${FLANNEL_VERSION}/kube-flannel.yml" \
  -o /tmp/kube-flannel.yml

# The pinned release manifest must match the kubeadm Pod CIDR.
grep -q '10.244.0.0/16' /tmp/kube-flannel.yml ||
  die "Flannel manifest does not contain expected Pod CIDR."

kubectl apply -f /tmp/kube-flannel.yml

log "Waiting for Flannel DaemonSet"
kubectl rollout status daemonset/kube-flannel-ds \
  -n kube-flannel --timeout=300s

log "Control-plane installation complete"
kubectl get nodes -o wide
kubectl get pods -A

echo
echo "Private IP: $NODE_IP"
echo "Pod CIDR: $POD_CIDR"
echo "Flannel VXLAN requires UDP 8472 between cluster nodes."
echo "Generate the worker join command with:"
echo "kubeadm token create --print-join-command"
