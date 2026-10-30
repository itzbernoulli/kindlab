#!/bin/bash
# Ensure the cks-bench namespace exists and clear any prior 'kube-bench' Job so the
# step starts fresh (a completed Job from a previous attempt would otherwise linger).
# Resource-level cleanup only — never drop the whole namespace.
kubectl get namespace cks-bench >/dev/null 2>&1 || kubectl create namespace cks-bench >/dev/null 2>&1
kubectl -n cks-bench delete job kube-bench --ignore-not-found --wait=false >/dev/null 2>&1
echo "cks-bench ready (create Job 'kube-bench' from aquasec/kube-bench, --targets node)"
