# Kubeadm: Creating Never-Expiring Tokens and Joining Worker Nodes

* Create a new Kubernetes token that **never expires**
* Get the **CA cert hash**
* Get the **full kubeadm join command** for your worker node

---

## Step 1: Create a token that never expires

Run this on your **control-plane node**:

```bash
kubeadm token create --ttl 0
```

* `--ttl 0` means the token **never expires**.
* It will output a token like:

```
abcdef.0123456789abcdef
```

Save this token.

---

## Step 2: Get the CA certificate hash

Run this on the **control-plane node**:

```bash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \
openssl rsa -pubin -outform der 2>/dev/null | \
openssl dgst -sha256 -hex | sed 's/^.* //'
```

This will print a hash like:

```
1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
```

---

## Step 3: Get control plane IP or hostname

Identify your control plane API server IP or hostname (let’s say it’s `192.168.1.100` for this example).

---

## Step 4: Construct the worker node join command

Now you can build the join command to run **on your worker node**:

```bash
kubeadm join 192.168.1.100:6443 --token abcdef.0123456789abcdef --discovery-token-ca-cert-hash sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
```

Replace:

* `192.168.1.100` with your control plane IP or hostname
* `abcdef.0123456789abcdef` with your token
* The sha256 hash with your CA cert hash from Step 2

---

## Bonus: Alternative - create token and print join command automatically

On the control plane node, you can run:

```bash
kubeadm token create --ttl 0 --print-join-command
```

This will:

* Create a **never expiring token**
* Print the **full join command** you can copy and run on worker nodes

---

