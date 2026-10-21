#!/bin/bash
V=$(kubectl -n labels-learn get pod frontend -o jsonpath='{.metadata.labels.env}' 2>/dev/null)
kubectl -n labels-learn get pod frontend >/dev/null 2>&1 || { echo "❌ pod 'frontend' not found"; exit 1; }
[ "$V" = "prod" ] || { echo "❌ pod frontend label env is '${V:-unset}', expected 'prod'"; exit 1; }
echo "✅ pod frontend has env=prod"; exit 0
