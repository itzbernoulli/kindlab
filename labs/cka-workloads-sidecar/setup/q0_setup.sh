#!/bin/bash
# Prepare sidecar-learn. Resource-level cleanup only (never delete the namespace).
NS=sidecar-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete deployment web --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete job batch-job --ignore-not-found >/dev/null 2>&1
echo "sidecar-learn ready (web + batch-job cleared)"
