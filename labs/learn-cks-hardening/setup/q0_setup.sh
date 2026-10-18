#!/bin/bash
# Reset the learn environment to a clean, idempotent slate.
# Recreates the cks-learn namespace and seeds the 'reader' ServiceAccount used by step 4.
kubectl delete namespace cks-learn --ignore-not-found --wait=false >/dev/null 2>&1
for i in $(seq 1 20); do kubectl get ns cks-learn >/dev/null 2>&1 || break; sleep 1; done
kubectl create namespace cks-learn >/dev/null 2>&1
kubectl -n cks-learn create serviceaccount reader >/dev/null 2>&1
# A couple of pods so 'list pods' has something to show.
kubectl -n cks-learn run demo --image=busybox:1.36 --restart=Never --command -- sleep 3600 >/dev/null 2>&1
echo "cks-learn ready (ServiceAccount 'reader' seeded)"
