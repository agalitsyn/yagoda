#!/usr/bin/env bash

find_cassandra_pods="kubectl get pods -l name=cassandra"

first_running_seed=$($find_cassandra_pods --no-headers | \
	grep Running | \
	grep 1/1 | \
	head -1 | \
	awk '{print $1}')

kubectl exec -ti $first_running_seed -- cqlsh --debug --color "$@"
