#!/bin/bash
# Reset the learn environment to a clean slate (idempotent).
kubectl delete namespace pod-design --ignore-not-found --wait=false >/dev/null 2>&1
# wait for namespace to be fully gone, then recreate clean
for i in $(seq 1 30); do kubectl get ns pod-design >/dev/null 2>&1 || break; sleep 1; done
kubectl create namespace pod-design >/dev/null 2>&1
echo "pod-design namespace ready (clean slate)"
