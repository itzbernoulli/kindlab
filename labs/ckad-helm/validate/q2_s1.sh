#!/bin/bash
# Step 2: demo-webapp scaled to EXACTLY 4 replicas via helm --set replicaCount=4.
R=$(kubectl get deploy demo-webapp -n helm-learn -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "$R" = "4" ]; then
  echo "✅ demo-webapp scaled to 4 replicas via helm --set replicaCount=4"; exit 0
fi
if [ -z "$R" ]; then
  echo "❌ Deployment 'demo-webapp' not found in helm-learn — install the release first (step 1), then helm upgrade with --set replicaCount=4"; exit 1
fi
echo "❌ demo-webapp has replicas=${R}, expected 4. Run: helm upgrade demo /tmp/webapp -n helm-learn --set replicaCount=4"; exit 1
