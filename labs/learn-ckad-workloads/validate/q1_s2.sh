#!/bin/bash
NS=workloads-learn
SPEC=$(kubectl -n "$NS" get deployment web -o jsonpath='{.spec.replicas}' 2>/dev/null)
READY=$(kubectl -n "$NS" get deployment web -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ -z "$SPEC" ]; then
  echo "❌ Deployment 'web' not found in $NS. Create then scale it to 4 replicas."; exit 1
fi
if [ "$SPEC" != "4" ]; then
  echo "❌ Deployment 'web' desired replicas is '$SPEC', expected 4. Run: kubectl -n $NS scale deployment web --replicas=4"; exit 1
fi
if [ "${READY:-0}" != "4" ]; then
  echo "❌ Deployment 'web' has ${READY:-0}/4 ready replicas; waiting for all 4 pods to become ready."; exit 1
fi
echo "✅ Deployment 'web' scaled to 4 ready replicas"; exit 0
