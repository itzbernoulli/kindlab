#!/bin/bash
if ! kubectl get node "$W2" >/dev/null 2>&1; then echo "❌ node '$W2' not found."; exit 1; fi
U=$(kubectl get node "$W2" -o jsonpath='{.spec.unschedulable}' 2>/dev/null)
if [ "$U" = "true" ]; then echo "✅ node $W2 is cordoned (unschedulable=true) and drained"; exit 0; fi
echo "❌ node '$W2' not cordoned (unschedulable='${U:-false}'). Run: kubectl cordon $W2 && kubectl drain $W2 --ignore-daemonsets --delete-emptydir-data"; exit 1
