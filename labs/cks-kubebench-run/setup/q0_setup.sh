#!/bin/bash
# Global reset to a clean, idempotent slate — RESOURCE-LEVEL cleanup only.
# Never drop the whole namespace (it races under parallel load and wipes the lab).
# Ensure the cks-bench namespace exists, then delete just the Jobs this lab builds.
NS=cks-bench
kubectl get namespace "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete job kube-bench kube-bench-master --ignore-not-found --wait=false >/dev/null 2>&1
echo "cks-bench ready (run kube-bench Jobs here)"
