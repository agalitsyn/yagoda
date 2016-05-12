#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(dirname "$0")"

export KUBECONFIG="$(realpath ${SCRIPT_DIR}/../kubeconfig)"

kubectl config use-context vagrant-multi
kubectl cluster-info
