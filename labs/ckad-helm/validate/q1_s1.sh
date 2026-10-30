#!/bin/bash
# Step 1: release 'demo' installed into helm-learn (release Secret helm.sh/release.v1 + Deployment demo-webapp).
SEC=$(kubectl get secret -n helm-learn -l owner=helm,name=demo -o jsonpath='{.items[0].type}' 2>/dev/null)
DEP=$(kubectl get deploy demo-webapp -n helm-learn -o name 2>/dev/null)
if [ "$SEC" = "helm.sh/release.v1" ] && [ -n "$DEP" ]; then
  echo "✅ helm release 'demo' installed in helm-learn (release Secret + Deployment demo-webapp present)"; exit 0
fi
if [ "$SEC" != "helm.sh/release.v1" ]; then
  echo "❌ no helm.sh/release.v1 Secret for release 'demo' in helm-learn (got type='${SEC:-none}'). Run: helm install demo /tmp/webapp -n helm-learn"; exit 1
fi
echo "❌ release Secret exists but Deployment 'demo-webapp' is missing in helm-learn — scaffold with 'helm create webapp' then 'helm install demo /tmp/webapp -n helm-learn'"; exit 1
