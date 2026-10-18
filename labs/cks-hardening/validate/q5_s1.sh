#!/bin/bash
NS=restricted-ns
ENF=$(kubectl get ns "$NS" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null)
VER=$(kubectl get ns "$NS" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce-version}' 2>/dev/null)
if [ "$ENF" = "restricted" ] && [ "$VER" = "v1.29" ]; then
  echo "✅ $NS enforces PSA level 'restricted' pinned to v1.29"; exit 0
fi
echo "❌ $NS PSA labels wrong (enforce='${ENF:-none}', enforce-version='${VER:-none}'). Need enforce=restricted and enforce-version=v1.29."; exit 1
