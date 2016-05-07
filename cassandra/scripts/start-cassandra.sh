#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$0")"

kubectl label nodes 127.0.0.1 name=cassandra

kubectl create -f $SCRIPT_DIR/../k8s/peer-service.yaml
kubectl create -f $SCRIPT_DIR/../k8s/service.yaml
kubectl create -f $SCRIPT_DIR/../k8s/daemonset.yaml --validate=false
