#!/bin/bash
# Check node $W1 has taint key=workload value=batch effect=NoSchedule.
MATCH=$(kubectl get node "$W1" -o jsonpath="{range .spec.taints[?(@.key=='workload')]}{.value}:{.effect}{'\n'}{end}" 2>/dev/null | grep -c '^batch:NoSchedule$')
if [ "${MATCH:-0}" -ge 1 ]; then echo "✅ node $W1 has taint workload=batch:NoSchedule"; exit 0; fi
echo "❌ node '$W1' missing taint workload=batch:NoSchedule. Run: kubectl taint nodes $W1 workload=batch:NoSchedule"; exit 1
