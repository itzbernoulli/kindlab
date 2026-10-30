#!/bin/bash
# Prep for the Falco lab. Idempotent and resource-level (never drops the whole
# namespace, which races under load and wipes the lab). Ensure 'falco' ns exists,
# remove only the specific objects this lab creates, and make the Helm repo ready.
NS=falco

# Ensure the working namespace exists (do NOT delete it).
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1

# Resource-level cleanup: drop any prior Falco install + helper objects so Step 1
# starts clean, WITHOUT deleting the namespace.
helm uninstall falco -n "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete daemonset falco --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete configmap falco falco-rules falco-custom-rules --ignore-not-found >/dev/null 2>&1
kubectl delete pod trip --ignore-not-found --force --grace-period=0 >/dev/null 2>&1

# Make the chart repo available so 'helm install' works in Step 1.
if command -v helm >/dev/null 2>&1; then
  helm repo add falcosecurity https://falcosecurity.github.io/charts >/dev/null 2>&1
  helm repo update >/dev/null 2>&1
  echo "learn-cks-falco ready: namespace '$NS' present, prior install cleared, falcosecurity repo added"
else
  echo "learn-cks-falco ready: namespace '$NS' present — note: 'helm' not found on host, install Falco via the falcosecurity chart"
fi
