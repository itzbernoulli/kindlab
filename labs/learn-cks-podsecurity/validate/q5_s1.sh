#!/bin/bash
NS=cks-locked
kubectl get ns "$NS" >/dev/null 2>&1 || { echo "❌ namespace $NS not found."; exit 1; }
ENF=$(kubectl get ns "$NS" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null)
VER=$(kubectl get ns "$NS" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce-version}' 2>/dev/null)
[ "$ENF" = "restricted" ] || { echo "❌ enforce label is '${ENF:-unset}', expected restricted. Set pod-security.kubernetes.io/enforce=restricted."; exit 1; }
[ "$VER" = "v1.30" ] || { echo "❌ enforce-version is '${VER:-unset}', expected v1.30. Pin pod-security.kubernetes.io/enforce-version=v1.30."; exit 1; }
echo "✅ cks-locked enforces the restricted standard pinned to v1.30"
exit 0
