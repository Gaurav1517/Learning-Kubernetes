# ETCD Backup and Restore on Kubernetes Cluster

This guide provides the steps for performing an ETCD backup and restore in a Kubernetes cluster.

## 1. Check Cluster Nodes

```bash
kubectl get nodes -o wide
```

## 2. Check Pods

```bash
kubectl get pod -A
```

## 3. Create a Test Deployment and Its 5 Replicas

Before taking the ETCD backup, let's create a test deployment to ensure there is data to back up.

```bash
kubectl create deployment test \
  --image=nginx \
  --dry-run=client \
  -o yaml | \
  tee deployment.yaml | \
  sed 's/replicas: 1/replicas: 5/' | \
  kubectl apply -f -
```

## 4. Check the Deployment, ReplicaSet, and Pod of the Project

```bash
kubectl get deployments.apps,rs,pods
```

## 5. Install `etcdctl` on the Cluster Control Plane

```bash
sudo apt install etcd-client
```

## 6. Check the ETCD-Controlplane Database

```bash
kubectl -n kube-system get pod
kubectl -n kube-system describe pod etcd-controlplane
```

## 7. Get Details of ETCD from This Path

```bash
vim /etc/kubernetes/manifests/etcd.yaml
```

## 8. Export `ETCDCTL_API` in the System

```bash
export ETCDCTL_API=3
```

## 9. Take an ETCD Snapshot Backup

To create a backup, run the following command:

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
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /tmp/backup.db
```

## 10. Verify the Backup

Check the backup file manually to ensure it exists:

```bash
ls -l /tmp/backup.db
cat /tmp/backup.db
```

## 11. Verify Snapshot Status

You can check the status of the snapshot with this command:

```bash
ETCDCTL_API=3 etcdctl --write-out=table snapshot status /tmp/backup.db
```

## 12. Restore the ETCD Backup Database

To restore the ETCD database, use the following command:

```bash
ETCDCTL_API=3 etcdctl --data-dir /var/lib/etcd-backup snapshot restore /tmp/backup.db
```

## 13. Edit `/etc/kubernetes/manifests/etcd.yaml`

Modify the `etcd.yaml` file to include the following:

```yaml
volumes:
  - hostPath:
      path: /var/lib/etcd
      type: DirectoryOrCreate
    name: etcd-data

path: /var/lib/etcd-backup
```

## 14. Restart the Kubelet Service

After making changes, restart the kubelet service:

```bash
systemctl restart kubelet.service
systemctl status kubelet.service
```

## 15. Verify the Backup Deployment, ReplicaSet, and Pod

Finally, verify that the deployment, replica set, and pod are in place:

```bash
kubectl get deployment,rs,pods
```

## References

- [Kubernetes ETCD Backup and Restore](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)
- [DevOps Cube - Backup and Restore ETCD in Kubernetes](https://www.devopscube.com/backup-restore-etcd-kubernetes/)
- [killercoda](https://killercoda.com/)


This file provides a step-by-step guide for backing up and restoring ETCD in a Kubernetes cluster.
Let me know if you need anything else!
