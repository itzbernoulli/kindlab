#!/bin/bash
# Reset the exam namespace to a clean, idempotent slate so Start/Reset always works.
kubectl delete namespace exam --ignore-not-found --wait=false >/dev/null 2>&1
# wait for it to be fully gone, then recreate
for i in $(seq 1 60); do kubectl get ns exam >/dev/null 2>&1 || break; sleep 1; done
kubectl create namespace exam >/dev/null 2>&1
echo "namespace 'exam' reset and ready"
