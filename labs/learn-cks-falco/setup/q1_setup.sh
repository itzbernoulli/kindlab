#!/bin/bash
# Prep for Step 1: make sure the Helm repo the student needs is available, and that
# no prior Falco install is lingering. Idempotent; safe to re-run.
helm uninstall falco -n falco >/dev/null 2>&1
kubectl delete namespace falco --ignore-not-found --wait=false >/dev/null 2>&1
for i in $(seq 1 20); do kubectl get ns falco >/dev/null 2>&1 || break; sleep 1; done
if command -v helm >/dev/null 2>&1; then
  helm repo add falcosecurity https://falcosecurity.github.io/charts >/dev/null 2>&1
  helm repo update >/dev/null 2>&1
  echo "falcosecurity Helm repo added; ready to install Falco"
else
  echo "helm not found on host — install Falco via the falcosecurity chart"
fi
