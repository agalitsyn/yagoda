#!/usr/bin/env bash

K8S_DOCKER_REGISTRY_PORT=5000
K8S_DOCKER_HOST=localhost
K8S_DOCKER_MACHINE_NAME=k8s
K8S_API_PORT=8080
K8S_VERSION=v1.2.3
K8S_CLUSTER_NAME=test-doc


cat >&1 <<EOT
Usage: source dev-tools.sh

Requirements: docker, docker-machine, kubectl

Recommended order:
    1. create-docker-machine
    2. run-k8s-docker
    3. setup-environment

EOT


function create-docker-machine() {
    if [[ -z $(docker-machine env $K8S_DOCKER_MACHINE_NAME) ]]; then
        docker-machine create --driver virtualbox --engine-insecure-registry "$K8S_DOCKER_HOST:$K8S_DOCKER_REGISTRY_PORT" "$K8S_DOCKER_MACHINE_NAME"
        docker-machine ssh $(docker-machine active) 'mkdir -pv ~/bin'
        docker-machine ssh $(docker-machine active) "wget http://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kubectl -O ~/bin/kubectl"
        docker-machine ssh $(docker-machine active) 'chmod 0755 ~/bin/kubectl'
        docker-machine ssh $(docker-machine active) 'echo "export PATH=$PATH:~/bin" >> ~/.ashrc'
    fi
    docker-machine env $K8S_DOCKER_MACHINE_NAME
}


function setup-environment() {
    kubectl config set-cluster $K8S_CLUSTER_NAME --server=http://$K8S_DOCKER_HOST:$K8S_API_PORT
    kubectl config set-context $K8S_CLUSTER_NAME --cluster=$K8S_CLUSTER_NAME
    kubectl config use-context $K8S_CLUSTER_NAME

    docker-machine ssh $(docker-machine active) -N -L $K8S_API_PORT:$K8S_DOCKER_HOST:$K8S_API_PORT
}


function run-k8s-docker() {
    docker run \
        --volume=/:/rootfs:ro \
        --volume=/sys:/sys:ro \
        --volume=/var/lib/docker/:/var/lib/docker:rw \
        --volume=/var/lib/kubelet/:/var/lib/kubelet:rw \
        --volume=/var/run:/var/run:rw \
        --net=host \
        --pid=host \
        --privileged=true \
        --name=kubelet \
        -d \
        gcr.io/google_containers/hyperkube-amd64:${K8S_VERSION} \
        /hyperkube kubelet \
            --containerized \
            --hostname-override="127.0.0.1" \
            --address="0.0.0.0" \
            --api-servers=http://$K8S_DOCKER_HOST:$K8S_API_PORT \
            --config=/etc/kubernetes/manifests \
            --cluster-dns=10.0.0.10 \
            --cluster-domain=cluster.local \
            --allow-privileged=true --v=2
}


function remove-k8s-docker() {
    local proceed=

    echo "Attention, it will destory all running containers"
    echo "Are you sure? (y/n)"

    read proceed
    if [ "$proceed" = 'N' ] || [ "$proceed" = 'n' ]; then
        echo "Canceled."
        return
    fi

    docker rm $(docker ps --filter=name=k8s --filter=name=kube --quiet --all)

    docker-machine ssh $(docker-machine active) 'sudo umount $(cat /proc/mounts | grep /var/lib/kubelet | awk '{print $2}''
    docker-machine ssh $(docker-machine active) 'sudo rm -rf /var/lib/kubelet'
}
