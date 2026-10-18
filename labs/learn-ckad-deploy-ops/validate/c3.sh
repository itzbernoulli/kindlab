#!/bin/bash
NS=deploy-learn
IMG=$(kubectl -n $NS get deploy api -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
GEN=$(kubectl -n $NS get deploy api -o jsonpath='{.metadata.generation}' 2>/dev/null)
UPD=$(kubectl -n $NS get deploy api -o jsonpath='{.status.updatedReplicas}' 2>/dev/null)
AVL=$(kubectl -n $NS get deploy api -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
[ -z "$IMG" ] && { echo "❌ deployment 'api' not found"; exit 1; }
[ "$IMG" = "nginx:1.25" ] || { echo "❌ api image is '$IMG', expected 'nginx:1.25' after rollback. Run: kubectl -n $NS rollout undo deployment/api"; exit 1; }
[ "${GEN:-0}" -lt 3 ] 2>/dev/null && { echo "❌ api generation ${GEN:-0} (<3) — do the 1.26 update first, then rollout undo"; exit 1; }
{ [ "${UPD:-0}" = "3" ] && [ "${AVL:-0}" = "3" ]; } || { echo "❌ rollback not complete: updated=${UPD:-0}/3 available=${AVL:-0}/3"; exit 1; }
echo "✅ api rolled back to nginx:1.25 (generation ${GEN}, 3/3 available)"; exit 0
