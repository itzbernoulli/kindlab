#!/bin/bash
U=$(kubectl get node "$W2" -o jsonpath='{.spec.unschedulable}' 2>/dev/null)
if [ "$U" = "true" ]; then echo "✅ node $W2 is cordoned (unschedulable) and drained"; exit 0; fi
echo "❌ node '$W2' not cordoned (unschedulable='${U:-false}'). Run: kubectl cordon $W2 && kubectl drain $W2 --ignore-daemonsets --delete-emptydir-data"; exit 1
