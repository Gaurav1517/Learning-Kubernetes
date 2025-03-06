# ETCD BACKUP AND RESTORE ON K8S CLUSTER

This guide provides the steps for performing ETCD backup and restore in a Kubernetes cluster.

## 1. Check Cluster Nodes

```bash
kubectl get nodes -o wide
```

## 2. Check Pods

```bash
kubectl get pod -A
```

## 3. Create Deployment and Its 5 Replicas

```bash
kubectl create deployment test \
  --image=nginx \
  --dry-run=client \
  -o yaml | \
  tee deployment.yaml | \
  sed 's/replicas: 1/replicas: 5/' | \
  kubectl apply -f -
```

## 4. Check Deployment, ReplicaSet, & Pod of Project

```bash
kubectl get deployments.apps,rs,pod
```

## 5. Install etcdctl in Cluster Control Plane

```bash
sudo apt install etcd-client
```

## 6. Check ETCD-Controlplane DB

```bash
kubectl -n kube-system get pod
kubectl -n kube-system describe pod etcd-controlplane
```

## 7. Get Details of ETCD from This Path

```bash
vim /etc/Kubernetes/manifest/etcd.yaml
```

## 8. Export ETCDCTL_API in System

```bash
export ETCDCTL_API=3
```

## 9. Take an ETCD Snapshot Backup

```bash
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=<ca-file> \
  --cert=<cert-file> \
  --key=<key-file> \
  snapshot save <backup-file-location>
```

Example:

```bash
ETCDCTL_API=3 etcdctl  \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /tmp/backup.db
```

## 10. Check Manually in /tmp/backup.db

```bash
ls -l /tmp/backup.db
cat /tmp/backup.db
```

## 11. Verify Snapshot Status

```bash
ETCDCTL_API=3 etcdctl --write-out=table snapshot status /tmp/backup.db
```

## 12. Restore Backup ETCD Database

```bash
ETCDCTL_API=3 etcdctl --data-dir /var/lib/etcd-backup snapshot restore /tmp/backup.db
```

## 13. Edit `/etc/kubernetes/manifest/etcd.yaml`

Add the following to your `etcd.yaml`:

```yaml
volumes:
  - hostPath:
      path: /var/lib/etcd
      type: DirectoryOrCreate
    name: etcd-data

path: /var/lib/etcd-backup
```

## 14. Restart Kubelet Service

```bash
systemctl restart kubelet.service
systemctl status kubelet.service
```

## 15. Verify Backup Deployment, ReplicaSet, Pod

```bash
kubectl get deployment,rs,pod
```

## References

- [Kubernetes ETCD Backup and Restore](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)
- [DevOps Cube - Backup and Restore ETCD in Kubernetes](https://devopscube.com/backup-etcd-restore-kubernetes/)
- [killercoda](https://killercoda.com/)
```

This file provides a step-by-step guide for backing up and restoring ETCD in a Kubernetes cluster.
Let me know if you need anything else!
