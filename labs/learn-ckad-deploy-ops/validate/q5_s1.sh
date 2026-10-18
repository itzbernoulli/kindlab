#!/bin/bash
NS=deploy-learn
if ! kubectl -n $NS get deploy worker >/dev/null 2>&1; then echo "❌ deployment 'worker' not found in $NS"; exit 1; fi
V=$(kubectl -n $NS get deploy worker -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="TIER")].value}' 2>/dev/null)
if [ "$V" != "backend" ]; then echo "❌ worker container has no env TIER=backend (got '${V:-none}'). Run: kubectl -n $NS set env deployment/worker TIER=backend"; exit 1; fi
echo "✅ existing deployment 'worker' now has env TIER=backend"; exit 0
