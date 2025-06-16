# **Kubernetes Authentication Guide**

## **Authentication Methods in Kubernetes**

Kubernetes supports multiple authentication methods for users to interact with the cluster. The most common methods are:

1. **Username & Password** *(Deprecated)*
2. **Username & Token** *(Deprecated)*
3. **Certificate-based Authentication** *(Recommended)*
4. **External Authentication Providers** (e.g., LDAP, OIDC)

---

## **Using Certificate-Based Authentication**

Certificate-based authentication is a secure and commonly used method in Kubernetes. This guide explains how to authenticate a user (e.g., `harry`) using certificates.

### **1. Setting Up a Certificate Authority (CA)**

A Certificate Authority (CA) is needed to sign client certificates for authentication.

1. **Create a directory to store certificates:**

   ```bash
   mkdir -p /certificate
   cd /certificate
   ```

2. **Copy the CA certificate (`ca.crt`) and key (`ca.key`) from the Kubernetes control plane node:**

   ```bash
   cp /etc/kubernetes/pki/ca.crt /certificate/
   cp /etc/kubernetes/pki/ca.key /certificate/
   ```

   Verify the files were copied successfully:

   ```bash
   ls /certificate
   ```

---

### **2. Creating User Certificates**

Next, generate a client certificate for the user (in this case, `harry`).

1. **Generate a private key for the user `harry`:**

   ```bash
   openssl genrsa -out harry.key 2048
   ```

2. **Create a Certificate Signing Request (CSR) for `harry`:**

   ```bash
   openssl req -new -key harry.key -subj "/CN=harry/O=qa" -out harry.csr
   ```

3. **Sign the user’s certificate using the CA's private key (`ca.key`) and certificate (`ca.crt`):**

   ```bash
   openssl x509 -req -in harry.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out harry.crt -days 365
   ```

4. **Clean up unnecessary files for security:**

   ```bash
   rm -rf ca.key harry.csr
   ```

---

### **3. Installing `kubectl` on the User Machine**

Since `harry` only needs to interact with the Kubernetes API server (e.g., via `kubectl`), you **only need to install `kubectl`**, not `kubelet` or any other components.

1. **Install `kubectl`:**

   On a CentOS/RHEL system, use the following commands to install `kubectl`:

   ```bash
   cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
   [kubernetes]
   name=Kubernetes
   baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
   enabled=1
   gpgcheck=1
   gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
   EOF
   ```

   Then, install `kubectl`:

   ```bash
   sudo dnf install -y kubectl --disableexcludes=kubernetes
   ```

   **Note:** If you are using a different Linux distribution or operating system, you can follow the official Kubernetes [installation guide for `kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/) for your specific platform.

2. **Verify the `kubectl` installation:**

   ```bash
   kubectl version --client
   ```

   This should show the client version of `kubectl`, confirming the installation was successful.

---

### **4. Copy Certificates to the Target Machine**

Now, we need to copy the `ca.crt`, `harry.crt`, and `harry.key` certificates to the machine where `harry` will use `kubectl`.

1. **Create a directory on the target machine (e.g., `harry`'s machine):**

   ```bash
   mkdir -p /home/harry/.kube
   ```

2. **Copy the certificates from the Certificate Authority node to `harry`'s machine:**

   ```bash
   scp /certificate/ca.crt /certificate/harry.crt /certificate/harry.key root@192.168.70.135:/home/harry/.kube/
   ```

---

### **5. Authenticate User `harry` with `kubectl`**

To authenticate `harry` and get resources from the Kubernetes API server using `kubectl`:

```bash
kubectl get pod --server=https://<k8s-api-server-endpoint>:6443 --client-certificate /home/harry/.kube/harry.crt --certificate-authority /home/harry/.kube/ca.crt --client-key /home/harry/.kube/harry.key
```

**Note:** If you see a **Forbidden** error, it means that the user `harry` is authenticated, but doesn't have the necessary authorization to access the resource. In this case, you would need to configure **Role-Based Access Control (RBAC)** to grant access to `harry`.

---

### **6. Configuring `kubectl` for User `harry`**

To avoid manually specifying the certificate and key in every `kubectl` command, you can configure `kubectl` to use them automatically.

1. **Ensure the `.kube` directory exists in `harry`'s home directory:**

   ```bash
   mkdir -p /home/harry/.kube
   ```

2. **Copy the `admin.conf` configuration file from the master node to `harry`'s machine:**

   ```bash
   scp /etc/kubernetes/admin.conf root@192.168.70.135:/home/harry/.kube/config
   ```

3. **Change the ownership of the config file:**

   ```bash
   sudo chown harry:harry /home/harry/.kube/config
   ```

4. **Edit the `config` file** to add `harry`'s certificates:

   ```bash
   vim /home/harry/.kube/config
   ```

   Update the `users` section to reflect `harry`'s credentials by replacing the `<base64-encoded>` placeholders with the actual base64 encoded values of `ca.crt`, `harry.crt`, and `harry.key`.

   **Example configuration:**

   ```yaml
   apiVersion: v1
   clusters:
   - name: kubernetes
     cluster:
       certificate-authority-data: <base64-encoded-ca.crt>
       server: https://<k8s-api-server-endpoint>:6443
   contexts:
   - name: harry@kubernetes
     context:
       cluster: kubernetes
       user: harry
   current-context: harry@kubernetes
   kind: Config
   preferences: {}
   users:
   - name: harry
     user:
       client-certificate-data: <base64-encoded-harry.crt>
       client-key-data: <base64-encoded-harry.key>
   ```

---

### **7. Get Base64 Encoded Certificate Data**

To get the base64 encoded certificate data for the CA certificate, user certificate, and user key, you can run the following commands:

1. **For the CA certificate:**

   ```bash
   cat /certificate/ca.crt | base64 -w0
   ```

2. **For the user certificate (`harry.crt`):**

   ```bash
   cat /certificate/harry.crt | base64 -w0
   ```

3. **For the user key (`harry.key`):**

   ```bash
   cat /certificate/harry.key | base64 -w0
   ```

Copy and paste the base64-encoded values into the `~/.kube/config` file in the appropriate sections.

---

### **8. Testing Authentication**

After configuring `kubectl`, test the authentication:

```bash
kubectl get pods
```

If `harry` is authorized to access the resources, the pods will be listed. If you see an authorization error, check the role and role bindings for `harry` in your Kubernetes cluster.

---

## **Troubleshooting**

* **Forbidden Errors**: If `harry` cannot access certain resources, ensure the correct **RBAC roles** and **role bindings** are in place for `harry`.
* **Certificate Errors**: Ensure that the certificates and keys are correctly configured in the `~/.kube/config` file.
* **`kubectl` Command Not Found**: If you get a "command not found" error, ensure `kubectl` is installed correctly and is in your system's `PATH`.

---
