#!/bin/bash
U=$(kubectl get node "$W2" -o jsonpath='{.spec.unschedulable}' 2>/dev/null)
if [ "$U" = "true" ]; then echo "✅ node $W2 is cordoned (unschedulable)"; exit 0; fi
echo "❌ node '$W2' not cordoned (unschedulable='${U:-false}'). Run: kubectl drain $W2 --ignore-daemonsets --delete-emptydir-data"; exit 1
