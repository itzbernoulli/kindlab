#!/bin/bash
# Clear any prior 'kube-bench-master' Job so the master-targets step starts fresh.
# Resource-level cleanup only — never drop the whole namespace.
kubectl get namespace cks-bench >/dev/null 2>&1 || kubectl create namespace cks-bench >/dev/null 2>&1
kubectl -n cks-bench delete job kube-bench-master --ignore-not-found --wait=false >/dev/null 2>&1
echo "cks-bench ready (create Job 'kube-bench-master', --targets master, pinned to the control plane)"
