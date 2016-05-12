# Kubernetes Cluster with Vagrant on CoreOS

This code copied from [coreos-kubernetes repository](https://github.com/coreos/coreos-kubernetes.git).

View the [full instructions](https://coreos.com/kubernetes/docs/latest/kubernetes-on-vagrant.html).

This deploy as simple as `vagrant up`.

Grab `kubectl` like this:
```
# Linux
curl -O https://storage.googleapis.com/kubernetes-release/release/v1.2.2/bin/linux/amd64/kubectl
# or MacOS X
curl -O https://storage.googleapis.com/kubernetes-release/release/v1.2.2/bin/darwin/amd64/kubectl

chmod +x kubectl
mv kubectl /usr/local/bin/kubectl
```

* View cluster status: `scripts/cluster_status.sh`.
* Use this cluster as default for local kubectl: `export KUBECONFIG=$(realpath kubeconfig); kubectl config use-context vagrant-multi`.

