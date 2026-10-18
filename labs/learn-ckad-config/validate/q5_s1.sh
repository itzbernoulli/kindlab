#!/bin/bash
NS=ckad-config
kubectl -n "$NS" get sa app-sa >/dev/null 2>&1 || { echo "❌ ServiceAccount app-sa not found in $NS. Create it: kubectl create sa app-sa -n $NS."; exit 1; }
kubectl -n "$NS" get pod sa-pod >/dev/null 2>&1 || { echo "❌ pod sa-pod not found in $NS. Create it from busybox:1.36."; exit 1; }
SAN=$(kubectl -n "$NS" get pod sa-pod -o jsonpath='{.spec.serviceAccountName}' 2>/dev/null)
[ "$SAN" != "app-sa" ] && { echo "❌ sa-pod serviceAccountName is '${SAN:-unset}', expected 'app-sa'."; exit 1; }
AM=$(kubectl -n "$NS" get pod sa-pod -o jsonpath='{.spec.automountServiceAccountToken}' 2>/dev/null)
[ "$AM" != "false" ] && { echo "❌ sa-pod automountServiceAccountToken is '${AM:-unset}', expected 'false'."; exit 1; }
if kubectl -n "$NS" exec sa-pod -- ls /var/run/secrets/kubernetes.io/serviceaccount/token >/dev/null 2>&1; then
  echo "❌ SA token is still mounted inside sa-pod — automountServiceAccountToken: false did not take effect."; exit 1
fi
echo "✅ sa-pod runs as SA app-sa with the API token NOT auto-mounted"; exit 0
