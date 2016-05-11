#!/usr/bin/env bash

set -e

SCRIPT_DIR=$(dirname $0)
PROJECT_DIR="$SCRIPT_DIR"

source "$PROJECT_DIR/tools/shell-functions.sh"

function vagrant_up() {
	announce-step "Bringing up vagrant VMs"

	pushd -- "$PROJECT_DIR/vagrant/"
	vagrant up
	popd
}

function wait_for_k8s() {
	announce-step "Waiting for K8S"

	local cmd="bash $PROJECT_DIR/vagrant/scripts/cluster_status.sh"
	wait-for-command "$cmd" 5 30
}

function k8s_cluster_check() {
	announce-step "Deploying test services to K8S"

	kubectl run nginx-test --image=nginx --port=80

	# Wait pod to appear
	local cmd='kubectl get pods -l run=nginx-test | grep ^nginx-test'
	wait-for-command "$cmd" 5 30

	# Determine pod to expose
	local pod=$(kubectl get pods -l run=nginx-test --no-headers | awk '{ print $1 }')
	kubectl expose pod "$pod" --target-port=80 --name=nginx-test \
		--type=LoadBalancer

	local nginx_endpoint="http://$(k8s-service-endpoint nginx-test 80)"
	wait-for-http "$nginx_endpoint" 5 30

	kubectl delete service nginx-test
	kubectl delete deployment nginx-test
}

function k8s_wait_for_workers() {
	announce-step "Waiting for 3 worker nodes"

	local cmd='[ $(kubectl get nodes --no-headers | wc -l) -eq 3 ]'
	wait-for-command "$cmd" 5 30
}

function deploy_registry() {
	announce-step "Deploying docker registry"

	make -C "$PROJECT_DIR/registry/" start

	local registry="http://$(k8s-service-endpoint kube-registry 5000 kube-system)"
	wait-for-http "$registry" 5 30
}

function deploy_prometheus() {
	announce-step "Deploying prometheus monitoring"

	local registry=$(k8s-service-endpoint kube-registry 5000 kube-system)
	REGISTRY="$registry" make -C "$PROJECT_DIR/prometheus/" start
}

function build_and_push_cassandra() {
	announce-step "Build'n'push cassandra images"

	local registry=$(k8s-service-endpoint kube-registry 5000 kube-system)
	REGISTRY="$registry" make -C "$PROJECT_DIR/cassandra/" build
	REGISTRY="$registry" make -C "$PROJECT_DIR/cassandra/" push
}

function main() {
	vagrant_up
	wait_for_k8s
	eval $(bash "$PROJECT_DIR/set-kubeconfig-vagrant.sh")
	k8s_cluster_check
	k8s_wait_for_workers
	announce-step "Setting labels on nodes"
	kubectl label node --all name=cassandra
	deploy_registry
	deploy_prometheus
	build_and_push_cassandra
}

main "$@"

