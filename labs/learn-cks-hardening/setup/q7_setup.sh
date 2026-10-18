#!/bin/bash
# Step 7 (SA token hardening): ensure ns exists; clear any prior attempt at the
# hardened SA/pod. RESOURCE-LEVEL cleanup — never delete the namespace.
NS=cks-learn
kubectl get namespace "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete pod hardened --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl -n "$NS" delete serviceaccount no-token --ignore-not-found >/dev/null 2>&1
echo "cks-learn ready (create SA 'no-token' with automount disabled + pod 'hardened' using it)"
