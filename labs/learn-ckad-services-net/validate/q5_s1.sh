#!/bin/bash
NS=svcnet-learn
kubectl -n $NS get svc api >/dev/null 2>&1 || { echo "❌ Service 'api' not found in $NS."; exit 1; }
SEL=$(kubectl -n $NS get svc api -o jsonpath='{.spec.selector.app}' 2>/dev/null)
[ "$SEL" = "api" ] || { echo "❌ Service 'api' selector app='$SEL', expected 'api' (it was seeded as api-WRONG)."; exit 1; }
N=$(kubectl -n $NS get endpoints api -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w | tr -d ' ')
[ "${N:-0}" -ge 1 ] || { echo "❌ Service 'api' has no endpoints; selector must match the app=api pods."; exit 1; }
echo "✅ Service api: selector fixed to app=api, $N endpoint(s) populated"
exit 0
