#!/bin/bash
# The deployed release's state Secret carries labels owner=helm, status=deployed, name=demo.
NAME=$(kubectl get secret -n helm-learn -l owner=helm,status=deployed,name=demo -o jsonpath='{.items[0].metadata.labels.name}' 2>/dev/null)
if [ "$NAME" = "demo" ]; then
  echo "✅ release 'demo' is listed as deployed in helm-learn"; exit 0
fi
echo "❌ no deployed release named 'demo' in helm-learn (found name='${NAME:-none}'). Confirm with: helm list -n helm-learn — it should show demo with status 'deployed'"; exit 1
