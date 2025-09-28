##  **StatefulSet + NFS-based dynamic provisioning** hands-on in Kubernetes. 
You **do not** need to manually create a PVC (`pvc.yaml`) — the **StatefulSet will dynamically create one for each replica** using the `volumeClaimTemplates`.

---

###  Summary of What You Need

| Component            | Description                                                             |
| -------------------- | ----------------------------------------------------------------------- |
| NFS Server           | Already configured on control-plane                                     |
| NFS Client           | Installed on **all nodes**                                              |
| External Provisioner | `nfs-subdir-external-provisioner` to dynamically provision PVCs via NFS |
| StorageClass         | Used by the provisioner for dynamic volumes                             |
| StatefulSet          | Will auto-create PVCs per replica using `volumeClaimTemplates`          |

---


###  Step 1: NFS Server Setup

If you've done this, you can skip. But just for reference:

<details>
<summary>Click to show NFS server setup steps</summary>

```bash
# On control-plane node
sudo dnf install -y nfs-utils

sudo mkdir -p /nfs/share
sudo chmod 777 /nfs/share

echo "/nfs/share *(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports
sudo systemctl enable --now nfs-server

sudo firewall-cmd --permanent --add-service=nfs
sudo firewall-cmd --permanent --add-service=mountd
sudo firewall-cmd --permanent --add-service=rpc-bind
sudo firewall-cmd --reload

sudo exportfs -rv
showmount -e localhost
```

</details>

---

###  Step 2: Install NFS Client on All Nodes

Run this on **each node** (control-plane + all workers):

```bash
sudo dnf install -y nfs-utils
```

Check:

```bash
showmount -e <CONTROL_PLANE_IP>
```

---

###  Step 3: Apply RBAC Configuration

Create `rbac.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nfs-client-provisioner
  namespace: default
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-client-provisioner-runner
rules:
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: run-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    namespace: default
roleRef:
  kind: ClusterRole
  name: nfs-client-provisioner-runner
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  namespace: default
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  namespace: default
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    namespace: default
roleRef:
  kind: Role
  name: leader-locking-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io
```

Apply:

```bash
kubectl apply -f rbac.yaml
```

---

###  Step 4: StorageClass

Create `class.yaml`:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-nfs-storage
provisioner: example.com/nfs
parameters:
  archiveOnDelete: "false"
reclaimPolicy: Retain
volumeBindingMode: Immediate
```

Apply:

```bash
kubectl apply -f class.yaml
```

---

###  Step 5: NFS Provisioner Deployment

Create `deployment.yaml` — **replace `192.168.44.131` with your control-plane node IP**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-client-provisioner
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nfs-client-provisioner
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: example.com/nfs
            - name: NFS_SERVER
              value: 192.168.44.131   # ← your control-plane IP
            - name: NFS_PATH
              value: /nfs/share
      volumes:
        - name: nfs-client-root
          nfs:
            server: 192.168.44.131   # ← your control-plane IP
            path: /nfs/share
```

Apply:

```bash
kubectl apply -f deployment.yaml
```

---

###  Step 6: StatefulSet (NO need for separate PVC)

Create file: `mysql-statefulset.yaml`

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  selector:
    matchLabels:
      app: mysql
  serviceName: "mysql"
  replicas: 1  # You can increase later
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
        - name: mysql
          image: mysql:8.0
          env:
            - name: MYSQL_ROOT_PASSWORD
              value: rootpass
          ports:
            - containerPort: 3306
              name: mysql
          volumeMounts:
            - name: mysql-persistent-storage
              mountPath: /var/lib/mysql
  volumeClaimTemplates:
    - metadata:
        name: mysql-persistent-storage
      spec:
        accessModes: [ "ReadWriteMany" ]
        storageClassName: "managed-nfs-storage"
        resources:
          requests:
            storage: 2Gi
```

Apply it:

```bash
kubectl apply -f mysql-statefulset.yaml
```

---

###  3. (Optional) Create Headless Service for DNS

Create file: `mysql-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  ports:
    - port: 3306
  clusterIP: None  # Headless
  selector:
    app: mysql
```

Apply it:

```bash
kubectl apply -f mysql-service.yaml
```

---

###  4. Check StatefulSet + PVCs

```bash
kubectl get pods
kubectl get pvc
```

You should see:

* Pod: `mysql-0`
* PVC: `mysql-persistent-storage-mysql-0`
* Volume folder: `/nfs/share/default-mysql-persistent-storage-mysql-0`

---

###  5. Access Pod and Create Database

```bash
kubectl exec -it mysql-0 -- bash
```

Inside the pod:

```bash
mysql -u root -p
# Enter password: rootpass
```

Inside MySQL prompt:

```sql
CREATE DATABASE testdb;
SHOW DATABASES;
```

You should see `testdb` listed.

 This DB is now **stored in your NFS volume**. If the pod restarts or moves, the data stays.

---

##  (Optional) Scale StatefulSet

Edit or patch the StatefulSet to 2 or more replicas:

```bash
kubectl scale statefulset mysql --replicas=2
```

You will now get:

* `mysql-0`, `mysql-1`
* New PVC: `mysql-persistent-storage-mysql-1`
* New NFS folder: `/nfs/share/default-mysql-persistent-storage-mysql-1`

Each pod has its own isolated MySQL instance + volume.

---

##  Final Checks

### 1. Check Pods

```bash
kubectl get pods
```

You should see 2 pods (`web-0`, `web-1`) running.

---

### 2. Check PVCs created by StatefulSet

```bash
kubectl get pvc
```

You should see PVCs like:

```
www-web-0   Bound
www-web-1   Bound
```

---

### 3. Check volumes in `/nfs/share`

On the NFS server (control-plane), run:

```bash
ls /nfs/share
```

You should see subdirectories like:

```
default-www-web-0
default-www-web-1
```

These were dynamically created by the provisioner.

---
## Refrences

1. [statefullSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
2. [nfs-provisioning](https://exxsyseng@bitbucket.org/exxsyseng/nfs-provisioning.git)
3. [rbac](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
4. [storageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/)
