#!/bin/bash
U=$(kubectl get node "$W2" -o jsonpath='{.spec.unschedulable}' 2>/dev/null)
if [ "$U" != "true" ]; then
  echo "❌ $W2 is not cordoned — a real drain cordons the node AND evicts its pods. Run: kubectl drain $W2 --ignore-daemonsets --delete-emptydir-data"; exit 1
fi
CNT=$(kubectl -n default get pods -l app=draintest -o jsonpath="{range .items[?(@.spec.nodeName=='$W2')]}{.metadata.name}{'\n'}{end}" 2>/dev/null | grep -c .)
if [ "${CNT:-0}" -eq 0 ]; then echo "✅ $W2 cordoned and no draintest pods remain on it"; exit 0; fi
echo "❌ $CNT draintest pod(s) still on $W2 — complete the drain (eviction)."; exit 1
