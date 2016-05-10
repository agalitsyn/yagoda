#!/usr/bin/env bash

set -e

function die() {
	echo "ERROR: $*" >&2
	exit 1
}

function announce-step() {
    echo
    echo "===> $*"
    echo
}

function wait-for-command() {
	local usage="$FUNCNAME <command> [poll_interval] [retries]"
	local cmd=${1:?$usage}
	local poll_interval=${2:-1}
	local attempts=${3:-10}

	attempt=1
	until $cmd >/dev/null 2>&1; do
		echo "Failed. Attempt $attempt of $attempts."

		if [[ $attempt -eq $attempts ]]; then
			die "all attempts were failed"
		fi

		sleep $poll_interval
		((attempt++))
	done
}

function wait-for-http() {
	local usage="$FUNCNAME <endpoint> [poll_interval] [retries]"
	local endpoint=${1:?$usage}
	local poll_interval=${2:-1}
	local attempts=${3:-10}

	wait-for-command \
		"curl --output /dev/null --silent --head --fail --max-time 1 $endpoint" \
		$poll_interval $attempts
}

function k8s-service-endpoint() {
	local usage="$FUNCNAME <service> <containerport> [namespace]"
	local service=${1:?$usage}
	local containerport=${2:?$usage}
	local namespace=${3:+"--namespace=$3"}

	local any_host=$(kubectl get nodes \
		-o jsonpath='{ .items[0].status.addresses[?(@.type == "InternalIP")].address }')
	local service_port=$(kubectl $namespace get service \
		-o jsonpath="{ .spec.ports[?(@.port == $containerport)].nodePort }" $service)

	echo "${any_host}:${service_port}"
}

