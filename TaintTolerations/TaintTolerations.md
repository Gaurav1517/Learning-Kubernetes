# Taints and Tolerations in Kubernetes

In Kubernetes (K8s), taints and tolerations are used to control how pods are scheduled on nodes.
A **taint** is applied to a node, and a **toleration** is applied to a pod. A pod can only be scheduled on a node 
if it tolerates the taints applied to that node.

### Taints

A taint is a key-value pair applied to a node that prevents pods from being scheduled on that node unless they have a corresponding toleration. Taints consist of three parts:

1. **Key**: The identifier for the taint.
2. **Value**: The value associated with the key.
3. **Effect**: The effect on the pod when the taint is matched. The possible effects are:
   - `NoSchedule`: Pods without the matching toleration will not be scheduled on the node.
   - `PreferNoSchedule`: Pods without the matching toleration will be scheduled elsewhere if possible, but it is not strictly enforced.
   - `NoExecute`: Pods without the matching toleration will be evicted if they are already running on the node.

### Tolerations

A toleration is applied to a pod to allow it to be scheduled on a node with a matching taint. A pod with a toleration can "tolerate" a tainted node and be scheduled on it.

## Example Use Case

Let's say you want to taint a node (`centos-worker-1`) so that only pods with a specific toleration can be scheduled there. For example, you could taint the node with `key=dedicated`, `value=high-priority`, and `effect=NoSchedule`.

### Steps to Apply Taint and Toleration:

#### Step 1: Apply a Taint to a Node

Taint the node using the following command:

```bash
kubectl taint nodes centos-worker-1 dedicated=high-priority:NoSchedule
```

This will prevent any pod from being scheduled on `centos-worker-1` unless the pod has a matching toleration.

#### Step 2: Apply a Toleration to a Pod

To allow a pod to be scheduled on `centos-worker-1`, the pod needs a toleration that matches the taint. Here's how you would define a toleration in a pod's spec:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example-pod
spec:
  containers:
  - name: nginx
    image: nginx
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "high-priority"
    effect: "NoSchedule"
```

This pod will be able to tolerate the taint (`dedicated=high-priority:NoSchedule`) on `centos-worker-1` and will be scheduled there.

### Explanation of Toleration Fields:
- **key**: The key of the taint to tolerate (in this case, `dedicated`).
- **operator**: Can be `Equal` or `Exists`. In this case, it’s `Equal`, meaning the value must match.
- **value**: The value that the pod should tolerate (in this case, `high-priority`).
- **effect**: The effect of the taint to tolerate (`NoSchedule` in this case).

#### Step 3: Verify Taints and Tolerations

You can verify the taints applied to the node with:

```bash
kubectl describe node centos-worker-1 | grep Taints
```

You can check if the pod tolerates the taint by looking at the pod’s description with:

```bash
kubectl describe pod example-pod
```

This will show whether the pod has the proper tolerations to be scheduled on the node with the taint.

### Tolerations with Multiple Effects

You can also have multiple tolerations with different effects. For example:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example-pod
spec:
  containers:
  - name: nginx
    image: nginx
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "high-priority"
    effect: "NoSchedule"
  - key: "other-key"
    operator: "Exists"
    effect: "NoExecute"
```

This pod will tolerate taints with the `NoSchedule` effect on the `dedicated=high-priority` taint, as well as any taints with the `NoExecute` effect.

## Taint and Toleration Lab Practice
Here’s the complete list of lab commands for practicing **Taints and Tolerations in Kubernetes** along with their descriptions:

## Taint and Toleration Lab Practice

### 1. **Get the list of nodes:**
```bash
kubectl get nodes
```
- This command lists all the nodes in your Kubernetes cluster. It helps you check which nodes are available for scheduling pods.

### 2. **Describe a specific node to view its details, including taints:**
```bash
kubectl describe node centos-master
```
- This command shows detailed information about a specific node, including its labels, taints, conditions, and other attributes.

### 3. **Get a list of pods:**
```bash
kubectl get pod
```
- This command lists all the pods in your current namespace. It is useful to check the status of the pods and which ones are running.

### 4. **Verify the taints applied to a node:**
```bash
kubectl describe node centos-master | grep -i taint
```
- This command filters and displays only the taints applied to the `centos-master` node, helping you check if there are any taints that could prevent pod scheduling.

### 5. **Apply a taint to a node:**
```bash
kubectl taint node centos-worker-1 team=prod:NoSchedule
```
- This command applies a taint to the `centos-worker-1` node, preventing any pod from being scheduled on it unless the pod has a matching toleration.

### 6. **Check the taints on the `centos-worker-1` node:**
```bash
kubectl describe node centos-worker-1 | grep -i taints
```
- This command shows the taints on the `centos-worker-1` node, which can be helpful to verify that the taint you applied was successful.

### 7. **Run a pod to test scheduling (without a toleration):**
```bash
kubectl run test --image=nginx
```
- This command creates a pod named `test` using the `nginx` image. Since the node is tainted, the pod will not be scheduled unless it has a matching toleration.

### 8. **Get the list of pods:**
```bash
kubectl get pod
```
- This command lists all the pods in the current namespace, which can be useful to check the status of the `test` pod after running it.

### 9. **Watch the pod's status:**
```bash
kubectl get pod --watch
```
- This command continuously watches for changes in pod status. This is helpful for observing the behavior of pods as they are scheduled or fail to be scheduled due to taints.

### 10. **Describe the pod's details:**
```bash
kubectl describe pod test
```
- This command provides detailed information about the pod `test`, including its scheduling information and reasons if it failed to be scheduled due to a taint.

### 11. **Show the last 4 lines of the pod's description:**
```bash
kubectl describe pod test | tail -n 4
```
- This command shows the last 4 lines of the pod's description. It can be useful to check the final lines for errors or scheduling issues.

### 12. **Delete the test pod:**
```bash
kubectl delete pod test
```
- This command deletes the `test` pod from the cluster.

### 13. **Get the list of nodes:**
```bash
kubectl get node
```
- This command lists all the nodes in the cluster to verify the status after applying taints and tolerations.

### 14. **Create a pod with tolerations using a dry-run and output to YAML:**
```bash
kubectl run test-1 --image=nginx --dry-run=client -o yaml > taint-toleration-pod.yaml
```
- This command creates a dry-run of a pod named `test-1` using the `nginx` image, outputting the spec as YAML to a file named `taint-toleration-pod.yaml`.

### 15. **Edit the YAML file for the pod to add tolerations:**
```bash
vim taint-toleration-pod.yaml
```
- This command opens the YAML file for editing. You can add the tolerations section manually to allow the pod to tolerate a specific taint.

### 16. **View the YAML file:**
```bash
cat taint-toleration-pod.yaml
```
- This command displays the contents of the YAML file, allowing you to verify that the tolerations have been correctly added.

### 17. **Create the pod using the YAML file:**
```bash
kubectl create -f taint-toleration-pod.yaml
```
- This command creates a pod from the YAML file, which contains the tolerations required to be scheduled on the tainted node.

### 18. **Get the list of pods to verify the pod creation:**
```bash
kubectl get pod
```
- This command lists all the pods, helping you verify that the pod was created successfully after applying the tolerations.

### 19. **Get nodes with detailed information:**
```bash
kubectl get node -o wide
```
- This command lists all the nodes with additional information, such as the internal and external IPs, which helps in identifying nodes more clearly.

### 20. **Get the details of a pod with wide output:**
```bash
kubectl get pod -o wide
```
- This command displays additional information about the pods, including the node they are scheduled on.

### 21. **Run a development pod (dev):**
```bash
kubectl run dev --image=nginx
```
- This command creates a development pod named `dev` using the `nginx` image. It is useful to test running other types of pods in the cluster.

### 22. **Check the taints on the nodes:**
```bash
kubectl describe nodes centos-master | grep -i taints
kubectl describe nodes centos-worker-1 | grep -i taints
```
- These commands check the taints applied to `centos-master` and `centos-worker-1`. It helps ensure that the correct taints are applied to the nodes.

### 23. **Remove a taint from a node:**
```bash
kubectl taint node centos-worker-1 team=prod:NoSchedule-
```
- This command removes the taint `team=prod:NoSchedule` from the `centos-worker-1` node, allowing any pod to be scheduled there without a corresponding toleration.

### 24. **Verify the taints again after removal:**
```bash
kubectl describe nodes centos-worker-1 | grep -i taints
```
- This command shows the taints on `centos-worker-1` after the taint removal to verify that the node is no longer tainted.

### 25. **Remove a taint from the `centos-master` node:**
```bash
kubectl taint node centos-master node-role.kubernetes.io/control-plane:NoSchedule-
```
- This command removes the `NoSchedule` taint from the `centos-master` node, allowing pods to be scheduled on it.

### 26. **Verify taints on the nodes after removal:**
```bash
kubectl describe nodes | grep -i taints
```
- This command shows the taints on all nodes after the taint removal. It ensures that the taints were successfully removed.

### 27. **Create a deployment with multiple replicas:**
```bash
kubectl create deploy test-deployment --image=nginx
```
- This command creates a deployment named `test-deployment` with the `nginx` image. It is useful for running multiple pods as part of a deployment.

### 28. **Scale the deployment to 5 replicas:**
```bash
kubectl scale --replicas=5 deployment test-deployment
```
- This command scales the `test-deployment` to 5 replicas, ensuring 5 pods are created and managed by the deployment.

### 29. **Check the status of the pods:**
```bash
kubectl get pod -o wide
```
- This command provides a list of pods and their associated nodes, allowing you to see where the pods are scheduled.

### 30. **Watch the status of the pods as they change:**
```bash
kubectl get pod -o wide --watch
```
- This command continuously watches for any changes to pod statuses, making it useful for observing pod creation or eviction events.

### 31. **Get detailed information about the nodes:**
```bash
kubectl describe node centos-master | grep -i taint
```
- This command checks for the taints applied to the `centos-master` node to verify the configuration.

### 32. **Apply a NoExecute taint to the `centos-master` node:**
```bash
kubectl taint node centos-master team=prod:NoExecute
```
- This command applies a `NoExecute` taint to the `centos-master` node, evicting pods that do not have a matching toleration.

### 33. **Verify the taint on the `centos-master` node:**
```bash
kubectl describe node centos-master | grep -i taint
```
- This command verifies that the `NoExecute` taint has been applied to the `centos-master` node.

### 34. **Get the wide output of pods after applying taints:**
```bash
kubectl get pod -o wide
```
- This command checks the pod status and ensures that pods are scheduled or evicted based on the applied taints.

```
