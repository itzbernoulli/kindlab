#!/bin/bash
# Reset the learn environment to a clean slate (idempotent).
# Uninstall any helm release, recreate the namespaces, and clear host scratch dirs
# so nothing passes on an untouched cluster.

# --- Helm side ---
helm uninstall demo -n helm-learn >/dev/null 2>&1
kubectl delete namespace helm-learn --ignore-not-found --wait=false >/dev/null 2>&1

# --- Kustomize side ---
kubectl delete namespace kustomize-learn --ignore-not-found --wait=false >/dev/null 2>&1

# Wait for namespaces to finish terminating, then recreate helm-learn.
for i in $(seq 1 30); do
  kubectl get ns helm-learn      >/dev/null 2>&1 && { sleep 1; continue; }
  break
done
kubectl create namespace helm-learn >/dev/null 2>&1

# Clear host scratch dirs used by the learner (chart + kustomize base).
rm -rf /tmp/webapp /tmp/kustomize-ckad 2>/dev/null

echo "helm-learn ready (namespace created); kustomize base will be seeded by step 4 setup"
