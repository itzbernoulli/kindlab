#!/bin/bash
# Re-seed step 1: a CrashLoopBackOff pod (command exits with an error immediately).
NS=ckad-observability
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl delete pod crasher -n "$NS" --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl run crasher -n "$NS" --image=busybox:1.36 \
  --command -- sh -c 'echo "boot: config file /etc/app.conf not found" >&2; exit 1' >/dev/null 2>&1
echo "seeded crashing pod 'crasher' (CrashLoopBackOff) in $NS"
