#!/bin/bash
# Step 5: $W2 must be schedulable AND hold no running drain-me pod.
U=$(kubectl get node "$W2" -o jsonpath='{.spec.unschedulable}' 2>/dev/null)
if [ "$U" = "true" ]; then
  echo "❌ node \$W2 ($W2) is still cordoned (unschedulable). After draining, run: kubectl uncordon $W2"; exit 1
fi
LEFT=$(kubectl -n default get pods -l app=drain-me -o jsonpath="{range .items[?(@.spec.nodeName=='$W2')]}{.metadata.name}={.status.phase} {end}" 2>/dev/null | grep -o 'Running' | grep -c .)
if [ "${LEFT:-0}" -ge 1 ]; then
  echo "❌ a drain-me pod is still Running on \$W2 ($W2) — the drain did not evict it. Run: kubectl drain $W2 --ignore-daemonsets --delete-emptydir-data --force"; exit 1
fi
echo "✅ \$W2 ($W2) is schedulable and holds no running drain-me pod"; exit 0
