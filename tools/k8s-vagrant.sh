#!/usr/bin/env bash

set -e

SCRIPT_DIR=$(dirname $0)

source "$SCRIPT_DIR/shell-functions.sh"

function vagrant_up() {
	announce-step "Bringing up vagrant VMs"

	pushd "$SCRIPT_DIR/../vagrant/"
	vagrant up
	popd
}

function wait_for_k8s() {
	announce-step "Waiting for K8S"

	local cluster_status="$SCRIPT_DIR/../vagrant/scripts/cluster_status.sh"
	wait-for-command "bash $cluster_status" 5 30
}

function k8s_cluster_check() {
	announce-step "Deploying test services to K8S"

	kubectl run nginx-test --image=nginx --port=80

	# Waiting for pods
	local cmd="kubectl get pods -l run=nginx-test | grep ^nginx-test"
	wait-for-command $cmd

	# Determine pod to expose
	local pod=$(kubectl get pods -l run=nginx-test \
		-o jsonpath='{ .items[0].metadata.name }')
	kubectl expose pod $pod --target-port=80 \
		--name=nginx-test --type=LoadBalancer

	local nginx_endpoint="http://$(k8s-service-endpoint nginx-test 80)"
	wait-for-http $nginx_endpoint 5 30

	kubectl delete service nginx-test
	kubectl delete deployment nginx-test
}

function deploy_registry() {
	announce-step "Deploying docker registry"

	make -C "$SCRIPT_DIR/../registry/" start

	local registry="http://$(k8s-service-endpoint kube-registry 5000 kube-system)"
	wait-for-http $registry 5 30
}

function deploy_prometheus() {
	announce-step "Deploying prometheus monitoring"

	local registry=$(k8s-service-endpoint kube-registry 5000 kube-system)
	REGISTRY=$registry make -C "$SCRIPT_DIR/../prometheus/" start
}

function build_and_push_cassandra() {
	announce-step "Build'n'push cassandra images"

	local registry=$(k8s-service-endpoint kube-registry 5000 kube-system)
	REGISTRY=$registry make -C "$SCRIPT_DIR/../cassandra/" build
	REGISTRY=$registry make -C "$SCRIPT_DIR/../cassandra/" push
}

function main() {
	vagrant_up
	wait_for_k8s
	eval $(bash "$SCRIPT_DIR/../vagrant/scripts/cluster_use.sh")
	k8s_cluster_check
	announce-step "Setting labels on nodes"
	kubectl label node --all name=cassandra
	deploy_registry
	deploy_prometheus
	build_and_push_cassandra
}

main $*
