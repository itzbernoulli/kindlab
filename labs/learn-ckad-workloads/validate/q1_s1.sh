#!/bin/bash
NS=workloads-learn
IMG=$(kubectl -n "$NS" get deployment web -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
SEL=$(kubectl -n "$NS" get deployment web -o jsonpath='{.spec.selector.matchLabels.app}' 2>/dev/null)
if [ -z "$IMG" ]; then
  echo "❌ Deployment 'web' not found in $NS. Create it: kubectl -n $NS create deployment web --image=nginx:1.25 --replicas=2"; exit 1
fi
if [ "$IMG" != "nginx:1.25" ]; then
  echo "❌ Deployment 'web' image is '$IMG', expected 'nginx:1.25'."; exit 1
fi
if [ "$SEL" != "web" ]; then
  echo "❌ Deployment 'web' selector app label is '${SEL:-none}', expected 'web'."; exit 1
fi
echo "✅ Deployment 'web' exists with image nginx:1.25 and selector app=web"; exit 0
