#!/bin/bash
NS=deploy-learn
if ! kubectl -n $NS get deploy api >/dev/null 2>&1; then echo "❌ deployment 'api' not found in $NS"; exit 1; fi
GEN=$(kubectl -n $NS get deploy api -o jsonpath='{.metadata.generation}' 2>/dev/null)
FOUND=$(kubectl -n $NS get rs -l app=api -o jsonpath='{range .items[*]}{.spec.template.spec.containers[0].image}{"\n"}{end}' 2>/dev/null | grep -c '^nginx:1.26$')
if [ "${GEN:-0}" -lt 2 ] 2>/dev/null; then echo "❌ api generation '${GEN:-0}' (<2) — no update yet. Run: kubectl -n $NS set image deployment/api api=nginx:1.26"; exit 1; fi
if [ "${FOUND:-0}" -lt 1 ]; then echo "❌ no rollout to nginx:1.26 found in api's ReplicaSet history. Run: kubectl -n $NS set image deployment/api api=nginx:1.26 (then rollout status)"; exit 1; fi
echo "✅ existing deployment 'api' was rolling-updated to nginx:1.26 (recorded in its ReplicaSet history)"; exit 0
