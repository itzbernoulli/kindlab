#!/bin/bash
# Prepare netpol-learn. Resource-level cleanup only (never delete the namespace).
NS=netpol-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete networkpolicy default-deny allow-client --ignore-not-found >/dev/null 2>&1
echo "netpol-learn ready (policies cleared)"
