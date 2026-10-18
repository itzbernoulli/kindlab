#!/bin/bash
# Distinct, host-dependent proof: the write attempt inside 'confined' was DENIED.
NS=cks-apparmor
R=$(kubectl -n "$NS" get configmap apparmor-proof -o jsonpath='{.data.result}' 2>/dev/null)
if [ -z "$R" ]; then
  echo "❌ create ConfigMap 'apparmor-proof' (key 'result') capturing the write attempt inside 'confined'"; exit 1
fi
if echo "$R" | grep -qi "permission denied"; then
  echo "✅ the write inside 'confined' was denied by AppArmor (result: $R)"; exit 0
fi
echo "❌ captured result shows no denial ('$R'). On an AppArmor host the write is 'Permission denied'; on this Mac it succeeds — run on your real cluster."; exit 1
