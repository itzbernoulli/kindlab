#!/bin/bash
NS=ckad-config
kubectl -n "$NS" get pod res-pod >/dev/null 2>&1 || { echo "❌ pod res-pod not found in $NS. Create it from busybox:1.36."; exit 1; }
RC=$(kubectl -n "$NS" get pod res-pod -o jsonpath='{.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
RM=$(kubectl -n "$NS" get pod res-pod -o jsonpath='{.spec.containers[0].resources.requests.memory}' 2>/dev/null)
LC=$(kubectl -n "$NS" get pod res-pod -o jsonpath='{.spec.containers[0].resources.limits.cpu}' 2>/dev/null)
LM=$(kubectl -n "$NS" get pod res-pod -o jsonpath='{.spec.containers[0].resources.limits.memory}' 2>/dev/null)
[ "$RC" != "100m" ] && { echo "❌ requests.cpu is '${RC:-unset}', expected '100m'."; exit 1; }
[ "$RM" != "64Mi" ] && { echo "❌ requests.memory is '${RM:-unset}', expected '64Mi'."; exit 1; }
[ "$LC" != "250m" ] && { echo "❌ limits.cpu is '${LC:-unset}', expected '250m'."; exit 1; }
[ "$LM" != "128Mi" ] && { echo "❌ limits.memory is '${LM:-unset}', expected '128Mi'."; exit 1; }
echo "✅ res-pod container has requests 100m/64Mi and limits 250m/128Mi"; exit 0
