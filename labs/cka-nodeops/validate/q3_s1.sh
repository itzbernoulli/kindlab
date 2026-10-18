#!/bin/bash
U=$(kubectl get node "$W1" -o jsonpath='{.spec.unschedulable}' 2>/dev/null)
if [ "$U" != "true" ]; then echo "✅ node $W1 is schedulable (not cordoned)"; exit 0; fi
echo "❌ node '$W1' still cordoned (unschedulable=true). Run: kubectl uncordon $W1"; exit 1
