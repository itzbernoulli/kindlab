#!/bin/bash
for ns in quota-compute quota-count lr-defaults lr-minmax; do kubectl delete namespace "$ns" --ignore-not-found --wait=false >/dev/null 2>&1; done
for ns in quota-compute quota-count lr-defaults lr-minmax; do
  for i in $(seq 1 20); do kubectl get ns "$ns" >/dev/null 2>&1 || break; sleep 1; done
  kubectl create namespace "$ns" >/dev/null 2>&1
done
echo "quota/limitrange namespaces ready"
