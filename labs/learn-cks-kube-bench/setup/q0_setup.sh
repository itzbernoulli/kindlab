#!/bin/bash
# Reset the learn environment to a clean, idempotent slate.
# Recreates the cks-bench namespace used by step 1 (kube-bench Job).
kubectl delete namespace cks-bench --ignore-not-found --wait=false >/dev/null 2>&1
for i in $(seq 1 20); do kubectl get ns cks-bench >/dev/null 2>&1 || break; sleep 1; done
kubectl create namespace cks-bench >/dev/null 2>&1
echo "cks-bench ready (run a kube-bench Job here)"
