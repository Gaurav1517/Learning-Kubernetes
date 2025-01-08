# ConfigMap in Kubernetes

## Overview

A **ConfigMap** in Kubernetes is a way to store configuration data as key-value pairs, which can be used by Pods and 
applications running in a Kubernetes cluster. Instead of hardcoding configuration settings, such as database connection
strings or application settings, directly into the application, you can store them in a ConfigMap. This approach enhances 
flexibility, as configuration changes can be made without rebuilding or redeploying the application.

## Why Use a ConfigMap?

1. **Separation of Configuration from Code**: Keep configuration separate from your application code.
2. **Easier Updates**: Update configurations without needing to rebuild or redeploy the container image.
3. **Reuse Across Applications**: Use the same ConfigMap with different Pods or applications for different
    environments (e.g., development, staging, production).

## Example of Using ConfigMap

### 1. **Create a ConfigMap**

You can create a ConfigMap either using a YAML file or via the command line.

#### **Using YAML:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  DATABASE_URL: "mysql://db-user:password@mysql-service:3306/mydb"
  APP_MODE: "production"
```

This example defines a ConfigMap `app-config` with two key-value pairs: `DATABASE_URL` and `APP_MODE`.

#### **Using the Command Line:**

```bash
kubectl create configmap app-config \
  --from-literal=DATABASE_URL="mysql://db-user:password@mysql-service:3306/mydb" \
  --from-literal=APP_MODE="production"
```

### 2. **Use the ConfigMap in a Pod**

Once the ConfigMap is created, you can use the values stored in it either as environment variables or mount them as files inside your Pod.

#### **Using Environment Variables:**

You can reference the ConfigMap keys directly in the Pod's environment variables using the `envFrom` or `env` fields.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: my-app
    image: my-app-image
    env:
    - name: DATABASE_URL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: DATABASE_URL
    - name: APP_MODE
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: APP_MODE
```

In this example, the `DATABASE_URL` and `APP_MODE` from the `app-config` ConfigMap are made available as environment variables in the container.

#### **Using ConfigMap as a File:**

You can also mount the ConfigMap as files inside your container by using the `volumes` field.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: my-app
    image: my-app-image
    volumeMounts:
    - name: config-volume
      mountPath: /app/config
  volumes:
  - name: config-volume
    configMap:
      name: app-config
```

In this case, the `app-config` ConfigMap will be mounted as files inside the container at the path `/app/config`.

## Key Benefits of Using ConfigMap

1. **Reusability**: A ConfigMap can be reused across multiple Pods.
2. **Flexibility**: You can change the configuration without restarting or redeploying Pods, if the application supports dynamic reloading.
3. **Centralized Management**: Store and manage all your configuration data in one place.

## Example Lab: Using ConfigMap in Kubernetes

### Without ConfigMap: Passing Environment Variables in a Pod

```bash
kubectl run variable-pod --image nginx -o yaml --dry-run=client > variable-pod.yaml
vim variable-pod.yaml
```

Add the environment variable `var` in the `variable-pod.yaml` file:

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: variable-pod
  name: variable-pod
spec:
  containers:
  - image: nginx
    name: variable-pod
    env:
      - name: var
        value: env-varaible
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

Create the Pod:

```bash
kubectl create -f variable-pod.yaml
kubectl get pod
kubectl exec -it variable-pod -- /bin/bash -c "env | grep var"
```

### Using ConfigMap in a Pod

Create a ConfigMap using the command:

```bash
kubectl create configmap myconfigmap --from-literal=user=admin --from-literal=password=secret
kubectl get cm
kubectl describe cm myconfigmap
```

#### **Create Pod Using ConfigMap:**

```bash
vim configmap.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: configmap-pod
  name: configmap-pod
spec:
  containers:
  - image: nginx
    name: configmap-pod
    envFrom:
      - configMapRef:
          name: myconfigmap
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

Create the Pod with the ConfigMap:

```bash
kubectl create -f configmap.yaml
kubectl get pod
kubectl exec -it configmap-pod -- /bin/bash -c "env | grep -E 'user|password'"
```

### Passing File in ConfigMap

Create a file and store variable values:

```bash
cat <<EOF | sudo tee configmap-file.yaml
name: configmap-file
value: configmap-file-value
EOF
```

Create the ConfigMap using the file:

```bash
kubectl create configmap configmap-file --from-file=configmap-file.yaml
kubectl get configmaps
kubectl describe configmap configmap-file
```

#### **Create Pod Using ConfigMap with File:**

```bash
vim configmap.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: configmap-pod
  name: configmap-pod
spec:
  containers:
  - image: nginx
    name: configmap-pod
    envFrom:
      - configMapRef:
          name: configmap-file
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

Create the Pod using ConfigMap with file:

```bash
kubectl create -f configmap.yaml
kubectl get pod configmap-pod
kubectl exec -it configmap-pod -- /bin/bash -c "env | grep configmap-file"
```
Here are five drawbacks of using ConfigMaps in Kubernetes:

1. **Limited Size**: ConfigMaps have a size limit (typically around 1MB). Storing large configuration data in a ConfigMap can lead to issues.

2. **No Secret Management**: ConfigMaps are not encrypted by default. Sensitive data (like passwords or API keys) should be stored in `Secrets` instead, as they provide better security.

3. **Risk of Overwriting**: If multiple pods or applications use the same ConfigMap, changes to the ConfigMap can unexpectedly affect all of them, potentially causing disruptions.

4. **No Version Control**: ConfigMaps don’t have built-in versioning. If you need to track changes to the configuration or roll back, you’ll need to manage versions manually.

5. **Not Ideal for Large Files**: Storing large configuration files in ConfigMaps can become inefficient and harder to manage. For bigger files, using persistent volumes or other storage solutions might be more appropriate.

These are some considerations to keep in mind when using ConfigMaps in Kubernetes.

## Summary

A ConfigMap in Kubernetes allows you to separate configuration data from application code, making your applications more adaptable and flexible. 
Whether you choose to use it as environment variables or as files, ConfigMaps provide a centralized, reusable, and easily updatable way to manage application configurations.
