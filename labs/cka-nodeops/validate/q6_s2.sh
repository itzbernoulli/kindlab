#!/bin/bash
PHASE=$(kubectl -n default get pod batch -o jsonpath='{.status.phase}' 2>/dev/null)
NODE=$(kubectl -n default get pod batch -o jsonpath='{.spec.nodeName}' 2>/dev/null)
if [ "$PHASE" = "Running" ] && [ "$NODE" = "$W1" ]; then echo "✅ pod 'batch' is Running on $W1"; exit 0; fi
echo "❌ pod 'batch' phase='${PHASE:-not found}' node='${NODE:-none}' (expected Running on $W1). The pod needs a toleration for workload=batch:NoSchedule and must land on $W1."; exit 1
