#!/usr/bin/env bash


function usage() {
    cat >&2 <<EOT
Usage: $0 {create-docker-machine|run-k8s-docker|post-deploy|forward-k8s-api-port|forward-k8s-docker-registry|remove-k8s-docker}

One-node kubernetes in docker for development.

General:
	Its not box-script, its just enhance speed of getting dev env.
	Ports forwards as synchronous processes, for avoiding mess of background processes, so you will need more that one terminal tab probably.

Requirements:
	docker, docker-machine, kubectl.

Note: additional kubectl will be installed inside docker-machine, sometimes its needed for port-forwarding, for example docker-registry.

Recommended order:
	1. create-docker-machine
	2. run-k8s-docker
	3. forward-k8s-api-port
	4. post-deploy

In addition you can create docker-registry and forward port using forward-k8s-docker-registry.

EOT
    exit 2
}


function create-docker-machine() {
	docker-machine create --driver virtualbox --engine-insecure-registry "$K8S_DOCKER_HOST:$K8S_DOCKER_REGISTRY_PORT" "$K8S_DOCKER_MACHINE_NAME"
	docker-machine ssh "$K8S_DOCKER_MACHINE_NAME" \
		"mkdir -pv ~/bin &&
		wget http://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kubectl -O ~/bin/kubectl &&
		chmod 0755 ~/bin/kubectl &&
		echo 'export PATH=\$PATH:~/bin' >> ~/.ashrc
		echo 'export KUBECONFIG=~/kubeconfig' >> ~/.ashrc"

	docker-machine scp "$KUBECONFIG" "$K8S_DOCKER_MACHINE_NAME:~/kubeconfig"
    docker-machine env "$K8S_DOCKER_MACHINE_NAME"
}


function post-deploy() {
	kubectl create -f - << EOF
kind: Namespace
apiVersion: v1
metadata:
  name: kube-system
EOF

	kubectl label nodes 127.0.0.1 name=cassandra
}


function forward-k8s-api-port() {
	echo "==> Forward $K8S_API_PORT"
	docker-machine ssh "$K8S_DOCKER_MACHINE_NAME" -N \
		-L "$K8S_API_PORT:$K8S_DOCKER_HOST:$K8S_API_PORT" 2>&1
}


function forward-k8s-docker-registry() {
	echo -n 'Waiting for pod (Interrupt with Control-C)'

	while true; do
		echo -n '.'
		POD=$(kubectl get pods --namespace=kube-system -l k8s-app=kube-registry \
				-o template --template '{{range .items}}{{.metadata.name}} {{.status.phase}}{{"\n"}}{{end}}' \
				| grep Running | head -1 | cut -f1 -d' ')
		if [[ -n "$POD" ]]; then
			echo "Got pod $POD"
			break
		fi
		sleep 1
	done

	echo '==> Forward 5000 port'
	kubectl port-forward --namespace=kube-system "$POD" 5000:5000 2>&1
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
		"gcr.io/google_containers/hyperkube-amd64:${K8S_VERSION}" \
		/hyperkube kubelet \
			--containerized \
			--hostname-override="127.0.0.1" \
			--address="0.0.0.0" \
			--api-servers="http://$K8S_DOCKER_HOST:$K8S_API_PORT" \
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

	docker-machine ssh "$K8S_DOCKER_MACHINE_NAME" 'sudo umount $(cat /proc/mounts | grep /var/lib/kubelet | awk '{print $2}''
	docker-machine ssh "$K8S_DOCKER_MACHINE_NAME" 'sudo rm -rf /var/lib/kubelet'
}


# Parse args
FUNC=${1:?$(usage)}

# Constants
K8S_DOCKER_REGISTRY_PORT=5000
K8S_DOCKER_HOST=localhost
K8S_DOCKER_MACHINE_NAME=k8s
K8S_API_PORT=8080
K8S_VERSION=v1.2.3
K8S_CLUSTER_NAME=dev-docker

SCRIPT_DIR="$(dirname "$0")"
export KUBECONFIG="${SCRIPT_DIR}/kubeconfig"

# Run
set -xe
"$FUNC"
