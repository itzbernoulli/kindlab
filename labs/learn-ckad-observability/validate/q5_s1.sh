#!/bin/bash
NS=ckad-observability
PATHV=$(kubectl get deploy ready-web -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}' 2>/dev/null)
AVAIL=$(kubectl get deploy ready-web -n "$NS" -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ -n "$AVAIL" ] && [ "$AVAIL" -ge 1 ]; then
  echo "✅ ready-web has $AVAIL available replica(s) (readiness probe path='${PATHV}')"; exit 0
fi
echo "❌ ready-web has 0 available replicas (probe path='${PATHV:-none}'). describe the pod to see the probe 404, then fix the httpGet path to '/'."; exit 1
