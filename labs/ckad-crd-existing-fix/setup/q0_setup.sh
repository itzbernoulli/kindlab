#!/bin/bash
# Reset to a clean slate WITHOUT deleting the namespace (ns delete races under load).
# Ensure the namespace exists, then do resource-level cleanup of everything this lab builds,
# and drop the CRDs the learner authors (steps 1 & 6) so each run starts fresh.
NS=crd-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1

# Remove learner-authored CRDs (their CRs are garbage-collected with them). Seeded CRDs
# (gizmos/robots/sprockets) are recreated by the per-step setups; drop them too for a clean slate.
for crd in widgets.stable.example.com regions.stable.example.com \
           gizmos.demo.example.com robots.demo.example.com sprockets.demo.example.com; do
  kubectl delete crd "$crd" --ignore-not-found --wait=true >/dev/null 2>&1
done

echo "crd-learn ready (namespace preserved; lab CRDs cleared for a fresh start)"
