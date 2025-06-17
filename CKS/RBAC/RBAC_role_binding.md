# **Kubernetes Authorization and RBAC Guide**

## **Authorization (Permissions on Resources)**

Kubernetes supports multiple modes of authorization to control user and service access to 
cluster resources. The most commonly used authorization modes are:

### 1. **RBAC (Role-Based Access Control) Authorization**

* Permissions are granted using roles and role bindings.
* Best practice for managing fine-grained access.

### 2. **ABAC (Attribute-Based Access Control) Authorization**

* Policy files define which attributes (like user and resource) allow access.
* Deprecated for many use cases and less dynamic than RBAC.

### 3. **Node Authorization**

* Specialized for kubelet to perform actions on their own resources (pods, secrets, etc.).

### 4. **Webhook Authorization**

* Delegates authorization to an external service using a webhook.

---

## **Check Active Authorization Modes**

Run the following command on the control plane node:

```bash
cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep -i " - --authorization-mode="
```

**Example Output:**

```bash
    - --authorization-mode=Node,RBAC
```

To use additional modes like ABAC:

```bash
--authorization-mode=Node,RBAC,ABAC
```

---

## **Check Kubernetes Resource Permissions**

### **For the Current User:**

```bash
kubectl auth can-i create pod
kubectl auth can-i get pod
```

### **For Another User (as kubernetes-admin):**

```bash
kubectl auth can-i create pod --as <username>
kubectl auth can-i get pod --as <username>
```

---

## **Using RBAC (Role-Based Access Control)**

RBAC allows defining access at **namespace** or **cluster** scope.

### **Types of Roles:**

1. **ClusterRole** – Cluster-wide access.
2. **Role** – Namespace-scoped access.

---

## **Check Resource Scope**

```bash
kubectl api-resources                  # all resources
kubectl api-resources --namespaced=true   # namespaced
kubectl api-resources --namespaced=false  # cluster-wide
```

---

## **Check Existing Cluster Roles**

```bash
kubectl get clusterrole
```

---

## **Create ClusterRoleBinding (Imperative Way)**

Grant cluster-admin rights to a user:

```bash
kubectl create clusterrolebinding <binding-name> --clusterrole=cluster-admin --user=<username>
```

Check it:

```bash
kubectl get clusterrolebinding | grep -i <binding-name>
```

Test permission:

```bash
kubectl auth can-i get pod --as=<username>
kubectl get pod --as=<username>
```

Delete the binding:

```bash
kubectl delete clusterrolebinding <binding-name>
```

---

## **Create Role and RoleBinding for User (Declarative Way)**

### **Reference**:

[RBAC Kubernetes Docs](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)

### **Create a Role:**

**File: `role.yaml`**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```

Create the role:

```bash
kubectl apply -f role.yaml
kubectl get role -n default
```

---

### **Create a RoleBinding:**

**File: `rolebinding.yaml`**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: User
  name: harry
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

Create the role binding:

```bash
kubectl apply -f rolebinding.yaml
kubectl get rolebinding -n default
```

---

## **Edit Role**

```bash
kubectl edit role pod-reader -n default
```

---

## **Check User Permissions**

After role binding:

```bash
kubectl auth can-i get pods --as=harry -n default
```

Try accessing resources (if authorized):

```bash
kubectl get pods --as=harry -n default
```

