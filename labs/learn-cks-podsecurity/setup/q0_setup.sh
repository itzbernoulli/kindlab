#!/bin/bash
# Reset the learn environment to a clean slate (idempotent).
kubectl delete namespace cks-podsec --ignore-not-found --wait=false >/dev/null 2>&1
kubectl delete namespace cks-locked --ignore-not-found --wait=false >/dev/null 2>&1
# wait for both namespaces to disappear so recreate is clean
for i in $(seq 1 30); do
  kubectl get ns cks-podsec >/dev/null 2>&1 && { sleep 1; continue; }
  kubectl get ns cks-locked >/dev/null 2>&1 && { sleep 1; continue; }
  break
done
kubectl create namespace cks-podsec >/dev/null 2>&1
# cks-locked starts WITHOUT any enforce label (step 5 adds it)
kubectl create namespace cks-locked >/dev/null 2>&1
kubectl label ns cks-locked pod-security.kubernetes.io/enforce- pod-security.kubernetes.io/enforce-version- --overwrite >/dev/null 2>&1
echo "cks-podsec ready; cks-locked created (no PSA label yet)"
