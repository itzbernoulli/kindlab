#!/bin/bash
SA=$(kubectl -n sa-learn get pod app -o jsonpath='{.spec.serviceAccountName}' 2>/dev/null)
kubectl -n sa-learn get pod app >/dev/null 2>&1 || { echo "❌ pod 'app' not found"; exit 1; }
[ "$SA" = "deployer" ] || { echo "❌ pod app serviceAccountName is '${SA:-default}', expected 'deployer'"; exit 1; }
echo "✅ pod app runs under serviceAccountName deployer"; exit 0
