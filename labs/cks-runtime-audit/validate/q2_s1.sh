#!/bin/bash
# RuntimeDefault seccomp at pod-level or container-level, pod Running.
T=$(kubectl get pod seccomp-default -n default -o jsonpath='{.spec.securityContext.seccompProfile.type}{" "}{.spec.containers[0].securityContext.seccompProfile.type}' 2>/dev/null)
PHASE=$(kubectl get pod seccomp-default -n default -o jsonpath='{.status.phase}' 2>/dev/null)
if echo "$T" | grep -q "RuntimeDefault" && [ "$PHASE" = "Running" ]; then
  echo "✅ pod seccomp-default uses RuntimeDefault seccomp and is Running"; exit 0
fi
echo "❌ pod seccomp-default type='${T:-none}' phase='${PHASE:-not found}' (expected seccompProfile.type RuntimeDefault and Running)"; exit 1
