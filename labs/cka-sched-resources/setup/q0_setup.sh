#!/bin/bash
# Prepare resources-learn. Resource-level cleanup only (never delete the namespace).
NS=resources-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete deployment rated hog --ignore-not-found >/dev/null 2>&1
echo "resources-learn ready (rated + hog cleared)"
