#!/bin/bash
A=$(kubectl -n deploy-learn get deploy worker -o jsonpath='{.spec.template.metadata.annotations.kubectl\.kubernetes\.io/restartedAt}' 2>/dev/null)
kubectl -n deploy-learn get deploy worker >/dev/null 2>&1 || { echo "❌ deployment 'worker' not found"; exit 1; }
[ -n "$A" ] || { echo "❌ worker has not been rollout-restarted (no kubectl.kubernetes.io/restartedAt annotation). Run: kubectl -n deploy-learn rollout restart deployment/worker"; exit 1; }
echo "✅ worker rolled via rollout restart (restartedAt=$A)"; exit 0
