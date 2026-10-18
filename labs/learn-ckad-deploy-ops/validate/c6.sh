#!/bin/bash
T=$(kubectl -n deploy-learn get deploy cache -o jsonpath='{.spec.strategy.type}' 2>/dev/null)
[ -z "$T" ] && { echo "❌ deployment 'cache' not found"; exit 1; }
[ "$T" = "Recreate" ] || { echo "❌ cache strategy.type is '$T', expected 'Recreate'"; exit 1; }
echo "✅ cache strategy.type == Recreate (changed in place)"; exit 0
