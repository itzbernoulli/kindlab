#!/bin/bash
NS=deploy-learn
S=$(kubectl -n $NS get deploy frontend -o jsonpath='{.spec.replicas}' 2>/dev/null)
R=$(kubectl -n $NS get deploy frontend -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[ -z "$S" ] && { echo "❌ deployment 'frontend' not found (Start re-seeds it; don't delete it)"; exit 1; }
[ "$S" = "4" ] || { echo "❌ frontend replicas is '$S', expected 4. Run: kubectl -n $NS scale deployment/frontend --replicas=4"; exit 1; }
[ "${R:-0}" = "4" ] || { echo "❌ frontend has ${R:-0}/4 ready replicas — waiting for all 4"; exit 1; }
echo "✅ frontend scaled to 4 ready replicas (in place)"; exit 0
