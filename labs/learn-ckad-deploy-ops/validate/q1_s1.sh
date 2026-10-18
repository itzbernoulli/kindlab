#!/bin/bash
NS=deploy-learn
S=$(kubectl -n $NS get deploy frontend -o jsonpath='{.spec.replicas}' 2>/dev/null)
R=$(kubectl -n $NS get deploy frontend -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ -z "$S" ]; then echo "❌ deployment 'frontend' not found in $NS (Start/Reset re-seeds it)"; exit 1; fi
if [ "$S" != "4" ]; then echo "❌ frontend desired replicas is '$S', expected 4. Run: kubectl -n $NS scale deployment/frontend --replicas=4"; exit 1; fi
if [ "${R:-0}" != "4" ]; then echo "❌ frontend has ${R:-0}/4 ready replicas — waiting for all 4 pods"; exit 1; fi
echo "✅ existing deployment 'frontend' scaled to 4 ready replicas"; exit 0
