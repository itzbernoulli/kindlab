#!/bin/bash
kubectl -n svcnet-learn get svc api-svc >/dev/null 2>&1 || { echo "❌ Service 'api-svc' not found (don't delete it — fix its selector)"; exit 1; }
IP=$(kubectl -n svcnet-learn get endpoints api-svc -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
[ -n "$IP" ] || { echo "❌ api-svc still has no endpoints — its selector doesn't match the 'api' pods. Patch spec.selector to app=api"; exit 1; }
echo "✅ api-svc now has endpoints ($IP) — selector fixed"; exit 0
