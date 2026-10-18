#!/bin/bash
NS=ckad-observability
PH=$(kubectl get pod bigask -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null)
CPU=$(kubectl get pod bigask -n "$NS" -o jsonpath='{.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
if [ "$PH" = "Running" ]; then
  echo "✅ bigask is Running (request now schedulable: cpu=${CPU:-unset})"; exit 0
fi
echo "❌ bigask is not Running (phase='${PH:-none}', cpu request='${CPU:-unset}'). describe it to see FailedScheduling/Insufficient cpu, then recreate with a sane CPU request such as 100m."; exit 1
