#!/bin/bash
# Reset the learn environment to a clean slate (idempotent).
kubectl delete namespace workloads-learn --ignore-not-found --wait=false >/dev/null 2>&1
# wait for the namespace to fully terminate, then recreate it empty
for i in $(seq 1 30); do kubectl get ns workloads-learn >/dev/null 2>&1 || break; sleep 1; done
kubectl create namespace workloads-learn >/dev/null 2>&1
echo "workloads-learn ready (empty namespace)"
