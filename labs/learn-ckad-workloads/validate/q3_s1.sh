#!/bin/bash
NS=workloads-learn
IMG=$(kubectl -n "$NS" get deployment web -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
GEN=$(kubectl -n "$NS" get deployment web -o jsonpath='{.metadata.generation}' 2>/dev/null)
UPD=$(kubectl -n "$NS" get deployment web -o jsonpath='{.status.updatedReplicas}' 2>/dev/null)
AVL=$(kubectl -n "$NS" get deployment web -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ -z "$IMG" ]; then
  echo "❌ Deployment 'web' not found in $NS."; exit 1
fi
if [ "$IMG" != "nginx:1.25" ]; then
  echo "❌ Deployment 'web' image is '$IMG', expected 'nginx:1.25' after rollback. Run: kubectl -n $NS rollout undo deployment/web"; exit 1
fi
# A genuine rollback (after the 1.26 update) means the spec changed at least a 3rd time.
if [ "${GEN:-0}" -lt 3 ] 2>/dev/null; then
  echo "❌ Deployment 'web' generation is '${GEN:-0}' (<3) — no rollback detected. Do the 1.26 rollout first, then: kubectl -n $NS rollout undo deployment/web"; exit 1
fi
if [ "${UPD:-0}" != "4" ] || [ "${AVL:-0}" != "4" ]; then
  echo "❌ Rollback not complete: updated=${UPD:-0}/4 available=${AVL:-0}/4. Wait: kubectl -n $NS rollout status deployment/web"; exit 1
fi
echo "✅ Deployment 'web' rolled back to nginx:1.25 (generation ${GEN}, 4/4 available)"; exit 0
