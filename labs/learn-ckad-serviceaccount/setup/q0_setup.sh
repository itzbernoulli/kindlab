#!/bin/bash
NS=sa-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete pod app locked token-pod --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl -n "$NS" delete sa deployer --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete secret regcred --ignore-not-found >/dev/null 2>&1
echo "sa-learn ready (clean slate — create the ServiceAccount + pods)"
