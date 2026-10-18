#!/bin/bash
# Ensure the cks-learn namespace exists and clear any prior attempt at the hardened SA/pod.
kubectl get namespace cks-learn >/dev/null 2>&1 || kubectl create namespace cks-learn >/dev/null 2>&1
kubectl -n cks-learn delete pod hardened --ignore-not-found --wait=false >/dev/null 2>&1
kubectl -n cks-learn delete serviceaccount no-token --ignore-not-found >/dev/null 2>&1
echo "cks-learn ready (create SA 'no-token' with automount disabled + pod 'hardened' using it)"
