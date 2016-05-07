#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$0")"

kubectl create -f $SCRIPT_DIR/../k8s/namespace.yaml
kubectl create -f $SCRIPT_DIR/../k8s/service.yaml
kubectl create -f $SCRIPT_DIR/../k8s/replication-controller.yaml

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

kubectl port-forward --namespace=kube-system $POD 5000:5000 2>&1 | logger &
