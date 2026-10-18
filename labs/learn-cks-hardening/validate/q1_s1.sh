#!/bin/bash
M=/etc/kubernetes/manifests/kube-scheduler.yaml
MODE=$(docker exec "$CP" stat -c '%a' "$M" 2>/dev/null)
if [ "$MODE" = "600" ]; then
  echo "✅ $M is mode 600 on $CP"; exit 0
fi
echo "❌ $M is mode '${MODE:-missing}' on $CP (expected 600). Run: docker exec $CP chmod 600 $M"; exit 1
