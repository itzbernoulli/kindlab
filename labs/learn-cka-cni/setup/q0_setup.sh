#!/bin/bash
# Restore CNI everywhere (in case a prior run left a node broken), reset namespace, seed the web deployment.
kubectl -n kube-system rollout restart ds kindnet >/dev/null 2>&1
kubectl -n kube-system rollout status ds kindnet --timeout=90s >/dev/null 2>&1
kubectl delete namespace cni-learn --ignore-not-found --wait=true >/dev/null 2>&1
kubectl create namespace cni-learn >/dev/null 2>&1
kubectl -n cni-learn create deployment web --image=nginx:alpine --replicas=3 >/dev/null 2>&1
echo "cni-learn ready (web deployment seeded; CNI healthy)"
