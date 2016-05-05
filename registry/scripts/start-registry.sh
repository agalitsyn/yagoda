#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$0")"

kubectl create -f $SCRIPT_DIR/../k8s/service.yaml
kubectl create -f $SCRIPT_DIR/../k8s/replication-controller.yaml

POD=$(kubectl get pods -l k8s-app=kube-registry \
            -o template --template '{{range .items}}{{.metadata.name}} {{.status.phase}}{{"\n"}}{{end}}' \
            | grep Running | head -1 | cut -f1 -d' ')

kubectl port-forward $POD 5000:5000
