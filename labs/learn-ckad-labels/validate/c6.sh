#!/bin/bash
V=$(kubectl -n labels-learn get pod frontend -o jsonpath='{.metadata.annotations.owner}' 2>/dev/null)
kubectl -n labels-learn get pod frontend >/dev/null 2>&1 || { echo "❌ pod 'frontend' not found"; exit 1; }
[ "$V" = "team-a" ] || { echo "❌ pod frontend annotation owner is '${V:-unset}', expected 'team-a'"; exit 1; }
echo "✅ pod frontend has annotation owner=team-a"; exit 0
