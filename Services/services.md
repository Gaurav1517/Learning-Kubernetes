# Kubernetes Services

## What Are Kubernetes Services?

In Kubernetes, services are used to expose applications running as pods to other pods or external clients. 
A service provides stable networking by abstracting pod IPs, which can change over time, and defining a 
consistent DNS name or IP address to access the pods. This ensures reliable communication within the 
cluster and external access when needed.

### Types of Services in Kubernetes
1. **ClusterIP (Default)**
   - Exposes the service on an internal IP in the cluster.
   - Only accessible from within the cluster.
   - Example:
     ```bash
     kubectl expose deployment <deploymentName> --type=ClusterIP --port=80
     ```

2. **NodePort**
   - Exposes the service on each node's IP address at a static port (default range: 30000–32767).
   - Accessible externally using `<Node-IP>:<NodePort>`.
   - Example:
     ```bash
     kubectl expose deployment <deploymentName> --type=NodePort --port=80
     ```

3. **LoadBalancer**
   - Provisions an external load balancer (cloud provider dependent).
   - Distributes traffic across pods.
   - Example:
     ```bash
     kubectl expose deployment <deploymentName> --type=LoadBalancer --port=80
     ```

4. **ExternalName**
   - Maps a service to an external DNS name.
   - Example:
     ```bash
     kubectl create service externalname <serviceName> --external-name=example.com
     ```

---

## Default Kubernetes Services
1. To list the default services:
   ```bash
   kubectl get svc
   ```

2. To list services in the `kube-system` namespace:
   ```bash
   kubectl get svc -n kube-system
   ```

3. To describe the `kube-dns` service:
   ```bash
   kubectl describe service kube-dns -n kube-system
   ```

4. To get detailed information about pods in the `kube-system` namespace:
   ```bash
   kubectl get pod -n kube-system -o wide
   ```

### Change the Service Cluster IP Range
To modify the service cluster IP range:
1. Edit the `kube-apiserver.yaml` file:
   ```bash
   vim /etc/kubernetes/manifest/kube-apiserver.yaml
   ```
   Update the `--service-cluster-ip-range` parameter:
   ```yaml
   --service-cluster-ip-range=10.125.170.0/24
   ```
   **Note:** Modifying this will cause the cluster to restart.

2. Reload the system services:
   ```bash
   systemctl daemon-reload
   systemctl restart kubelet
   systemctl status kubelet
   ```

3. Verify the configuration by creating a test pod and service:
   ```bash
   kubectl run test --image=nginx
   kubectl get pod
   kubectl expose pod test --name=<serviceName> --port=<service-port> --target-port=<pod-port>
   kubectl get service
   ```

---

## Creating a Service for a Deployment

### Create a Deployment
1. Generate a deployment YAML file:
   ```bash
   kubectl create deployment <deploymentName> --image=nginx:1.14.2 --replicas=3 -o yaml --dry-run=client > deployment.yaml
   ```

2. Edit the generated `deployment.yaml` file as needed:
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     labels:
       app: mydeployment
     name: mydeployment
   spec:
     replicas: 3
     selector:
       matchLabels:
         app: mydeployment
     template:
       metadata:
         labels:
           app: mydeployment
       spec:
         containers:
         - image: nginx:1.14.2
           name: nginx
   ```

3. Apply the deployment:
   ```bash
   kubectl create -f deployment.yaml
   ```

4. Verify the deployment:
   ```bash
   kubectl get -f deployment.yaml --show-labels
   kubectl describe deployment <deploymentName>
   kubectl get replicasets -l app=mydeployment
   kubectl get pod -l app=mydeployment
   ```

### Expose the Deployment as a Service
1. Generate a service YAML file:
   ```bash
   kubectl expose deployment <deploymentName> --type=NodePort --port=80 --target-port=80 -o yaml --dry-run=client > svc-mydeployment.yaml
   ```

2. Edit the generated `svc-mydeployment.yaml` file to specify a NodePort:
   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     labels:
       app: mydeployment
     name: mydeployment
   spec:
     ports:
     - port: 80
       protocol: TCP
       targetPort: 80
       nodePort: 30007
     selector:
       app: mydeployment
     type: NodePort
   ```

3. Apply the service:
   ```bash
   kubectl create -f svc-mydeployment.yaml
   ```

4. Verify the service:
   ```bash
   kubectl get -f svc-mydeployment.yaml --show-labels
   kubectl describe svc mydeployment
   ```

### Access the Service Outside the Cluster
1. Get the cluster IP and service NodePort:
   ```bash
   kubectl get node -o wide  # Cluster IP
   kubectl get service -l app=mydeployment # Service NodePort
   ```

2. Access the service:
   ```
   <Cluster-IP>:<NodePort>
   Example: 192.168.157.139:30007
   ```

3. Allow the port through the firewall (if applicable):
   ```bash
   firewall-cmd --zone=public --add-port=30007/tcp --permanent
   firewall-cmd --reload
   firewall-cmd --zone=public --list-ports
   ```

4. Add the port to the AWS security group (if applicable):
   - Go to your EC2 instance security group.
   - Add an inbound rule:
     - **Type:** Custom TCP
     - **Protocol:** TCP
     - **Port Range:** 30007
     - **Source:** 0.0.0.0/0
   - Save the rule.

### Additional Steps and Considerations
- Always ensure the port assigned for the NodePort service does not conflict with existing services.
- To troubleshoot service connectivity, check pod logs and verify network policies.
- For production environments, consider using LoadBalancer or Ingress controllers for better scalability and security.

Now, your service should be accessible from outside the cluster.

