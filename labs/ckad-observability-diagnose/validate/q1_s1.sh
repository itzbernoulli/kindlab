#!/bin/bash
NS=ckad-observability
PH=$(kubectl get pod crasher -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null)
RDY=$(kubectl get pod crasher -n "$NS" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)
if [ "$PH" = "Running" ] && [ "$RDY" = "true" ]; then
  echo "✅ crasher is Running and Ready (CrashLoop fixed)"; exit 0
fi
echo "❌ crasher is not Running/Ready (phase='${PH:-none}' ready='${RDY:-false}'). Read its logs, then recreate it with a long-lived command like: kubectl run crasher -n $NS --image=busybox:1.36 --command -- sleep 3600"; exit 1
