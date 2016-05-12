#!/bin/bash

set -e

SCRIPT_DIR="$(dirname "$0")"
PROJECT_DIR="$SCRIPT_DIR"

cat <<TAGTAG
export KUBECONFIG="$(realpath ${PROJECT_DIR}/vagrant/kubeconfig)" ;
kubectl config use-context vagrant-multi ;
TAGTAG

