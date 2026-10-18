#!/bin/bash
SA=$(kubectl get pod sa-restricted -n default -o jsonpath='{.spec.serviceAccountName}' 2>/dev/null)
PHASE=$(kubectl get pod sa-restricted -n default -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$SA" = "restricted" ] && [ "$PHASE" = "Running" ]; then
  echo "✅ pod sa-restricted uses ServiceAccount 'restricted' and is Running"; exit 0
fi
echo "❌ pod sa-restricted serviceAccountName='${SA:-none}' phase='${PHASE:-not found}' (expected serviceAccountName restricted and Running)"; exit 1
