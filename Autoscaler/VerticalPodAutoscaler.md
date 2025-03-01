############Configure metrics server##############
# Ref: https://github.com/kubernetes-sigs/metrics-server

# install dependencies
yum install -y wget
# wget the components.yaml
wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
ls
vim components.yaml
# Do not verify the CA of serving certificates presented by Kubelets. For testing purposes only.
 - --kubelet-insecure-tls
# To install the latest Metrics Server release from the components.yaml manifest, run the following command.
kubectl apply -f components.yaml
kubectl  get pod -n kube-system metrics-server-596474b58-87whw
kubectl -n kube-system describe pod metrics-server-596474b58-87whw
kubectl -n kube-system pod
# Verify metrics server is working properly by running this commands.
kubectl top nodes
kubectl top pod -A

# Adjust pod resources with Vertical Pod Autoscaler
Ref: https://docs.aws.amazon.com/eks/latest/userguide/vertical-pod-autoscaler.html

# Clone the kubernetes/autoscalerGitHub repository.
git clone https://github.com/kubernetes/autoscaler.git
ls
# Change to the vertical-pod-autoscaler directory.
cd autoscaler/vertical-pod-autoscaler/
ls
# (Optional) If you have already deployed another version of the Vertical Pod Autoscaler, remove it with the following command.
./hack/vpa-down.sh
# Deploy the Vertical Pod Autoscaler to your cluster with the following command.
 ./hack/vpa-up.sh
# Verify that the Vertical Pod Autoscaler Pods have been created successfully.
 kubectl get pods -n kube-system

## Test your Vertical Pod Autoscaler installation
# Deploy the hamster.yaml Vertical Pod Autoscaler example with the following command.
kubectl apply -f examples/hamster.yaml
# Get the Pods from the hamster example application.
 kubectl get pods -l app=hamster
 kubectl get --watch Pods -l app=hamster
 ![vpa-snap]()
 
#An example output is as follows.

hamster-c7d89d6db-rglf5   1/1     Running   0          48s
hamster-c7d89d6db-znvz5   1/1     Running

# Describe one of the Pods to view its cpu and memory reservation. Replace c7d89d6db-rglf5 with one of the IDs returned in your output from the previous step.
kubectl describe pod hamster-7cc74859c-4g9zm

# Wait for the vpa-updater to launch a new hamster Pods. This should take a minute or two. You can monitor the Pods with the following command.
kubectl get --watch Pods -l app=hamster

# When a new hamster Pods is started, describe it and view the updated CPU and memory reservations.
kubectl describe pod hamster-c7d89d6db-jxgfv

An example output is as follows.

[...]
Containers:
  hamster:
    Container ID:  docker://2c3e7b6fb7ce0d8c86444334df654af6fb3fc88aad4c5d710eac3b1e7c58f7db
    Image:         registry.k8s.io/ubuntu-slim:0.1
    Image ID:      docker-pullable://registry.k8s.io/ubuntu-slim@sha256:b6f8c3885f5880a4f1a7cf717c07242eb4858fdd5a84b5ffe35b1cf680ea17b1
    Port:          <none>
    Host Port:     <none>
    Command:
      /bin/sh
    Args:
      -c
      while true; do timeout 0.5s yes >/dev/null; sleep 0.5s; done
    State:          Running
      Started:      Fri, 27 Sep 2019 10:37:08 -0700
    Ready:          True
    Restart Count:  0
    Requests:
      cpu:        587m
      memory:     262144k
[...]
# When a new hamster Pods is started, describe it and view the updated CPU and memory reservations.
kubectl describe vpa/hamster-vpa

# When you finish experimenting with the example application, you can delete it with the following command.
kubectl delete -f examples/hamster.yaml
