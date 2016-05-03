#!/usr/bin/env bash

echo 'Nodes'
echo '====='
kubectl get nodes --label-columns="name"
echo

echo 'Services'
echo '========'
kubectl get services --selector="name=cassandra-peers"
echo
kubectl get services --selector="name=cassandra"
echo

echo 'Daemon sets'
echo '==========='
kubectl get daemonsets --selector="name=cassandra"
echo

echo 'Pods'
echo '===='
kubectl get pods --selector="name=cassandra"
