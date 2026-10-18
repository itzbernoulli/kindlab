#!/bin/bash
NS=deploy-learn
T=$(kubectl -n $NS get deploy cache -o jsonpath='{.spec.strategy.type}' 2>/dev/null)
if [ -z "$T" ]; then echo "❌ deployment 'cache' not found in $NS"; exit 1; fi
if [ "$T" != "Recreate" ]; then echo "❌ cache strategy.type is '${T}', expected 'Recreate'. Patch: kubectl -n $NS patch deployment cache -p '{\"spec\":{\"strategy\":{\"type\":\"Recreate\",\"rollingUpdate\":null}}}'"; exit 1; fi
echo "✅ existing deployment 'cache' strategy changed to Recreate"; exit 0
