*❤️जय श्री राधे कृष्णा❤️*
## **Kubernetes Documentation**
### Pod
Pods are the smallest deployable units of computing that you create and manage in Kubernetes. 
A Pod is  a group of one or more containers, with shared storage and network resources, and a specification for how to run the containers. A Pod's contents 
are always co-located and co-scheduled, and run in a shared context. A Pod models an application-specific "logical host": it contains one or more application containers 
which are relatively tightly coupled. In non-cloud contexts, applications executed on the same physical or virtual machine are analogous to cloud applications executed on the same logical host.
As well as application containers, a Pod can contain init containers that run during Pod startup. You can also inject ephemeral containers for debugging a running Pod.

### What is a Pod?
Note:
You need to install a container runtime into each node in the cluster so that Pods can run there.
The shared context of a Pod is a set of Linux namespaces, cgroups, and potentially other facets of isolation - the same things that isolate a container. Within a Pod's context, the individual applications may have further sub-isolations applied.
A Pod is similar to a set of containers with shared namespaces and shared filesystem volumes.

Pods in a Kubernetes cluster are used in two main ways:
•	Pods that run a single container. The "one-container-per-Pod" model is the most common Kubernetes use case; in this case, you can think of a Pod as a wrapper
around a single container; Kubernetes manages Pods rather than managing the containers directly.
•	Pods that run multiple containers that need to work together. A Pod can encapsulate an application composed of multiple co-located containers that are
tightly coupled and need to share resources. These co-located containers form a single cohesive unit.

Grouping multiple co-located and co-managed containers in a single Pod is a relatively advanced use case. You should use this pattern only in specific instances
in which your containers are tightly coupled.
You don't need to run multiple containers to provide replication (for resilience or capacity); if you need multiple replicas, see Workload management.

## Using Pods

---
### Viewing Pod Options with `kubectl explain`

To see the available options for a Pod, use the `explain` keyword:
```bash
kubectl explain pod
kubectl explain pod.metadata
kubectl explain pod.spec
kubectl explain pod.spec.containers
```
---

### Creating a Manual File for a Pod

You can create a Pod manually by writing a YAML file. Example:
```bash
vim my-pod.yml
```

Content of `my-pod.yml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dev
spec:
  containers:
  - name: dev
    image: nginx:1.14.2
    ports:
    - containerPort: 80
```
---

### Generating Declarative Syntax for a Pod Using an Imperative Command

Use the `--dry-run=client` option to get the declarative syntax for a Pod:
```bash
kubectl run sysops --image=nginx --dry-run=client -o yaml
```

Output:
```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: sysops
  name: sysops
spec:
  containers:
  - image: nginx
    name: sysops
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

Save the `--dry-run=client` output to a file for declarative use:
```bash
kubectl run <podName> --image=<imageName> --dry-run=client -o yaml > <fileName.yml>
```
---

### Creating a Pod from a File (Declarative Approach)

Run the following command to create a Pod using a YAML file:
```bash
kubectl create -f <filePath/to/fileName.yml>
```
---

### Checking the `etcd` Database File

To check the YAML definition of a Pod stored in the `etcd` database:
```bash
kubectl get pod <podName> -o yaml
```
---

### Backing Up a Pod

To take a backup of a Pod:
```bash
kubectl get pod <podName> -o yaml > <backupFile.yaml>
```

### Restoring a Pod from a Backup File

Create a Pod using the backup file:
```bash
kubectl create -f <backupFile.yaml>
```
---

### Verifying and Describing a Pod

- **Check the Pod:**
  ```bash
  kubectl get pod
  ```

- **Describe the Pod:**
  ```bash
  kubectl describe pod <podName>
  ```
---

### Inspecting Pod Details

The command sequence below shows how to inspect Pod details:

1. **`kubectl get pod`:** Displays a list of all Pods in the current namespace, including their basic details:
   - **NAME:** Pod's name.
   - **READY:** Indicates how many containers in the Pod are ready.
   - **STATUS:** The current status of the Pod (e.g., Running, Pending).
   - **RESTARTS:** Number of times the Pod's containers have restarted.
   - **AGE:** How long the Pod has been running.

   **Example Output:**
   ```
   NAME   READY   STATUS    RESTARTS   AGE
   test   1/1     Running   0          27s
   ```

2. **`kubectl get pod <podName> -o wide`:** Retrieves detailed information about the specified Pod in a more extensive format. The additional fields include:
   - **IP:** The Pod's internal IP address.
   - **NODE:** The name of the node hosting the Pod.
   - **NOMINATED NODE:** A node that might be considered for scheduling this Pod if it is waiting for resources.
   - **READINESS GATES:** Any conditions required for the Pod to be marked as ready.

   **Example Output:**
   ```
   NAME   READY   STATUS    RESTARTS   AGE   IP              NODE       NOMINATED NODE   READINESS GATES
   test   1/1     Running   0          50s   172.16.226.69   worker-1   <none>           <none>
   ```
---

### Accessing a Running Pod’s Shell

To access the shell of a running Pod, use the following command:
```bash
kubectl exec -it <podName> -- /bin/bash
```

**Explanation:**
1. **`kubectl exec`:** Executes a process inside a container in a Pod.
2. **`-it`:** Enables interactive mode with a terminal attached:
   - **`-i`:** Keeps the session open for interaction.
   - **`-t`:** Allocates a pseudo-terminal.
3. **`<podName>`:** Replace `<podName>` with the name of the Pod you want to access.
4. **`-- /bin/bash`:** Specifies the command to run inside the container, in this case, the Bash shell.

**Notes:**
- If the container does not have `/bin/bash` (common in lightweight images like Alpine), you can try `/bin/sh`:
  ```bash
  kubectl exec -it <podName> -- /bin/sh
  ```
- If the Pod contains multiple containers, specify the container name using `--container`:
  ```bash
  kubectl exec -it <podName> -c <containerName> -- /bin/bash
  ```

**Example:**
```bash
kubectl exec -it my-app -- /bin/bash
```
This command gives you an interactive shell inside the `my-app` Pod, where you can execute commands within the container's environment.
---

### Listing Container Names in a Pod

To list the container names within a Pod that has multiple containers, use:
```bash
kubectl get pod <podName> -o jsonpath='{.spec.containers[*].name}'
```

**Explanation:**
- **`kubectl get pod`:** Retrieves information about the specified Pod.
- **`-o jsonpath='{.spec.containers[*].name}'`:** Extracts the names of all containers defined in the Pod's specification.

**Example:**
Suppose the Pod name is `multi-container-pod`. Run the command:
```bash
kubectl get pod multi-container-pod -o jsonpath='{.spec.containers[*].name}'
```
**Output:**
```
container1 container2 container3
```

**Alternative Method:**
Use `kubectl describe pod` and look under the **Containers** section to see the container names manually:
```bash
kubectl describe pod <podName>
```
Look for lines similar to:
```
Containers:
  container1:
  container2:
```
With the container names, you can specify the target container when executing commands, such as:
```bash
kubectl exec -it <podName> -c <containerName> -- /bin/bash
```
---
To view the labels of Kubernetes pods, you can use the kubectl command with the appropriate options.
Command to See Labels of Pods
kubectl get pods --show-labels
Explanation
•	kubectl get pods: Lists all the pods in the current namespace.
•	--show-labels: Displays the labels associated with each pod.

View Labels in JSON or YAML Format
If you want more detailed information about the labels, you can describe or output the pod information in JSON or YAML:
Describe Pod
```bash
kubectl describe pod <pod-name>
```
This command shows detailed information about the pod, including its labels.
Get Pod Labels in JSON
```bash
kubectl get pod <pod-name> -o jsonpath='{.metadata.labels}'
```
Get Pod Labels in YAML
```bash
kubectl get pod <pod-name> -o yaml
```
Replace <pod-name> with the name of the specific pod.

Delete a pod using the type and name specified in pod.yaml
```bash
kubectl delete -f  <filelName.yaml>
```

Delete pod with imperative command (manually) 
```bash
kubectl delete pod <podName>
```

Delete all pods
```bash
kubectl delete pods --all
```
