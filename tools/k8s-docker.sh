#!/usr/bin/env bash

K8S_DOCKER_REGISTRY_PORT=5000
K8S_DOCKER_HOST=localhost
K8S_DOCKER_MACHINE_NAME=k8s
K8S_API_PORT=8080
K8S_VERSION=v1.2.3
K8S_CLUSTER_NAME=dev-docker

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export KUBECONFIG="${DIR}/kubeconfig"

cat >&1 <<USAGE
One-node kubernetes ($K8S_VERSION) in docker for development.

Usage: source k8s-docker.sh

Requirements: docker, docker-machine, kubectl.

Recommended order:
	1. create-docker-machine
	2. run-k8s-docker
	3. setup-environment

USAGE


function create-docker-machine() {
	docker-machine create --driver virtualbox --engine-insecure-registry "$K8S_DOCKER_HOST:$K8S_DOCKER_REGISTRY_PORT" "$K8S_DOCKER_MACHINE_NAME"
	# in addition place kubectl inside docker-machine, sometimes it's needed for port-forwarding
	docker-machine ssh $K8S_DOCKER_MACHINE_NAME \
		"mkdir -pv ~/bin &&
		wget http://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kubectl -O ~/bin/kubectl &&
		chmod 0755 ~/bin/kubectl &&
		echo 'export PATH=\$PATH:~/bin' >> ~/.ashrc
		echo 'export KUBECONFIG=~/kubeconfig' >> ~/.ashrc"
	docker-machine scp $KUBECONFIG $K8S_DOCKER_MACHINE_NAME:~/kubeconfig
    docker-machine env $K8S_DOCKER_MACHINE_NAME
}


function setup-environment() {
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
