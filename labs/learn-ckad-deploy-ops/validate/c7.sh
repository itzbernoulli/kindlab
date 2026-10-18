#!/bin/bash
P=$(kubectl -n deploy-learn get deploy frontend -o jsonpath='{.spec.template.spec.containers[0].imagePullPolicy}' 2>/dev/null)
kubectl -n deploy-learn get deploy frontend >/dev/null 2>&1 || { echo "❌ deployment 'frontend' not found"; exit 1; }
[ "$P" = "IfNotPresent" ] || { echo "❌ frontend container imagePullPolicy is '${P:-unset}', expected 'IfNotPresent' (set it with kubectl patch --type=json)"; exit 1; }
echo "✅ frontend imagePullPolicy == IfNotPresent (via JSON patch)"; exit 0
