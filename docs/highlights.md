# Project highlights

## Overview

Set of k8s resources to deploy a 3 node Cassandra 3.0.5 cluster on K8s 1.2.2.

## Deploy

* Should be automated in "one click" fashion.
* Should enforce system requirements (amount of nodes, CPU, RAM, etc).
* Should be checked (all nodes can communicate to each other).
* Should have an "success" event, detect if it has finished successfully.

## Monitoring

* All layers of infrastructure should have monitoring.
* Monitoring should be integrated woth infrastructure software primitives (like readiness checks).

## Logging

* Logs should be accesible using standard `kubectl` commands.

## Dependencies

* No specific dependencies, only `kubectl` and `ssh`.
* Keep it simple, use only k8s jobs and daemon sets.

## Documentation

* How-to for external people, tutorial how to launch, test and use project.
* Architecture, for more detailed view.
* Bright future plans: implementing cluster expansion/upgrade/reconfiguration.

All docs should be filled with command examples, outputs examples and diagrams.

## Functional testing

* Simple tests checks that cluster is operational.

## Demo

* Should be as simple as `vagrant up`.

## Continuous integrations

* All code should be linted.
* All documentations should be spell-checked.

