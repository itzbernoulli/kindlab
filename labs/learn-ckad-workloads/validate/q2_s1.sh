#!/bin/bash
# Step 2 asks for a rolling update to nginx:1.26. Step 3 then rolls back to 1.25,
# so we must NOT grade on the *current* image (it legitimately reverts). Instead we
# verify the persistent evidence of the 1.26 rollout: a ReplicaSet for this
# Deployment whose pod template used nginx:1.26 still exists in the revision history.
NS=workloads-learn
if ! kubectl -n "$NS" get deployment web >/dev/null 2>&1; then
  echo "❌ Deployment 'web' not found in $NS."; exit 1
fi
GEN=$(kubectl -n "$NS" get deployment web -o jsonpath='{.metadata.generation}' 2>/dev/null)
FOUND=$(kubectl -n "$NS" get rs -l app=web \
  -o jsonpath='{range .items[*]}{.spec.template.spec.containers[0].image}{"\n"}{end}' 2>/dev/null \
  | grep -c '^nginx:1.26$')
if [ "${GEN:-0}" -lt 2 ] 2>/dev/null; then
  echo "❌ Deployment 'web' generation is '${GEN:-0}' (<2) — no rollout yet. Run: kubectl -n $NS set image deployment/web web=nginx:1.26"; exit 1
fi
if [ "${FOUND:-0}" -lt 1 ]; then
  echo "❌ No rollout to nginx:1.26 found in the Deployment's ReplicaSet history. Run: kubectl -n $NS set image deployment/web web=nginx:1.26 (then rollout status)"; exit 1
fi
echo "✅ A rolling update to nginx:1.26 is recorded in the Deployment's history (its ReplicaSet survives even after the step-3 rollback)"; exit 0
