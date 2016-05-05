#!/bin/bash

set -e

SCRIPT_DIR="$(dirname "$0")"

cat <<TAGTAG
export KUBECONFIG="\${KUBECONFIG}:${SCRIPT_DIR}/../kubeconfig" ;
kubectl config use-context vagrant-multi ;
TAGTAG

