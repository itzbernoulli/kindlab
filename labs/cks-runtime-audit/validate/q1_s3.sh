#!/bin/bash
PHASE=$(kubectl get pod seccomp-audit -n default -o jsonpath='{.status.phase}' 2>/dev/null)
NODE=$(kubectl get pod seccomp-audit -n default -o jsonpath='{.spec.nodeName}' 2>/dev/null)
if [ "$PHASE" = "Running" ] && [ "$NODE" = "$W1" ]; then
  echo "✅ pod seccomp-audit is Running on $W1"; exit 0
fi
echo "❌ pod seccomp-audit phase='${PHASE:-not found}' node='${NODE:-none}' (expected Running on $W1)"; exit 1
