#!/bin/bash
POD="static-web-$W1"
PHASE=$(kubectl get pod "$POD" -n default -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PHASE" = "Running" ]; then echo "✅ mirror pod $POD is Running"; exit 0; fi
echo "❌ mirror pod '$POD' phase='${PHASE:-not found}' (expected Running). Static pods appear as <name>-<node>; give the kubelet ~15s."; exit 1
