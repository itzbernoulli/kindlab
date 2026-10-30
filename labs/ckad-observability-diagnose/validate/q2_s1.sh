#!/bin/bash
NS=ckad-observability
AVAIL=$(kubectl get deploy web -n "$NS" -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
DESIRED=$(kubectl get deploy web -n "$NS" -o jsonpath='{.spec.replicas}' 2>/dev/null)
IMG=$(kubectl get deploy web -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
if echo "$IMG" | grep -q "does-not-exist"; then
  echo "❌ Deployment web still points at the bad image '$IMG'. Fix it: kubectl set image deploy/web web=nginx:1.25-alpine -n $NS"; exit 1
fi
if [ -n "$AVAIL" ] && [ -n "$DESIRED" ] && [ "$AVAIL" -ge "$DESIRED" ]; then
  echo "✅ Deployment web is Running ($AVAIL/$DESIRED available, image=$IMG)"; exit 0
fi
echo "❌ Deployment web not fully available yet (available='${AVAIL:-0}' desired='${DESIRED:-?}' image='${IMG:-none}'). Diagnose with describe/events and set a pullable image like nginx:1.25-alpine."; exit 1
