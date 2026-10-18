#!/bin/bash
NS=deploy-learn
kubectl -n $NS get deploy api >/dev/null 2>&1 || { echo "❌ deployment 'api' not found"; exit 1; }
GEN=$(kubectl -n $NS get deploy api -o jsonpath='{.metadata.generation}' 2>/dev/null)
F=$(kubectl -n $NS get rs -l app=api -o jsonpath='{range .items[*]}{.spec.template.spec.containers[0].image}{"\n"}{end}' 2>/dev/null | grep -c '^nginx:1.26$')
[ "${GEN:-0}" -lt 2 ] 2>/dev/null && { echo "❌ api generation ${GEN:-0} (<2) — no update yet. Run: kubectl -n $NS set image deployment/api api=nginx:1.26"; exit 1; }
[ "${F:-0}" -lt 1 ] && { echo "❌ no rollout to nginx:1.26 in api's ReplicaSet history. Run: kubectl -n $NS set image deployment/api api=nginx:1.26"; exit 1; }
echo "✅ api rolling-updated to nginx:1.26 (recorded in ReplicaSet history)"; exit 0
