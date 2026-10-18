#!/bin/bash
PHASE=$(kubectl get pod readonly-root -n default -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PHASE" = "Running" ]; then echo "✅ pod readonly-root is Running"; exit 0; fi
echo "❌ pod readonly-root phase='${PHASE:-not found}' (expected Running — if CrashLoop, ensure /tmp is writable via emptyDir)"; exit 1
