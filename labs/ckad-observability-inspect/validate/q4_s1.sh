#!/bin/bash
NS=ckad-observability
if ! kubectl get pod logger -n "$NS" >/dev/null 2>&1; then
  echo "❌ create pod 'logger' that prints 'MARKER=ckad-obs-42' to stdout and stays up"; exit 1
fi
LOG=$(kubectl logs logger -n "$NS" 2>/dev/null)
if ! echo "$LOG" | grep -q "MARKER=ckad-obs-42"; then
  echo "❌ logger's logs don't contain 'MARKER=ckad-obs-42' yet. Run it with: sh -c 'echo MARKER=ckad-obs-42; sleep 3600'"; exit 1
fi
VAL=$(kubectl get configmap captured -n "$NS" -o jsonpath='{.data.token}' 2>/dev/null)
if [ "$VAL" = "ckad-obs-42" ]; then
  echo "✅ logger printed the marker AND configmap captured has token=ckad-obs-42"; exit 0
fi
echo "❌ configmap 'captured' is missing or token!='ckad-obs-42' (got token='${VAL:-none}'). Read the marker with kubectl logs, then: kubectl create configmap captured -n $NS --from-literal=token=ckad-obs-42"; exit 1
