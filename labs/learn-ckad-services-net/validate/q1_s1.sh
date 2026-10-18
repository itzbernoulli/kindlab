#!/bin/bash
NS=svcnet-learn
TYPE=$(kubectl -n $NS get svc web -o jsonpath='{.spec.type}' 2>/dev/null)
[ -n "$TYPE" ] || { echo "❌ Service 'web' not found in $NS. Create a ClusterIP Service named web."; exit 1; }
[ "$TYPE" = "ClusterIP" ] || { echo "❌ Service 'web' type is '$TYPE', expected ClusterIP."; exit 1; }
PORT=$(kubectl -n $NS get svc web -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
TP=$(kubectl -n $NS get svc web -o jsonpath='{.spec.ports[0].targetPort}' 2>/dev/null)
[ "$PORT" = "80" ] || { echo "❌ Service 'web' port is '$PORT', expected 80."; exit 1; }
[ "$TP" = "8080" ] || { echo "❌ Service 'web' targetPort is '$TP', expected 8080."; exit 1; }
N=$(kubectl -n $NS get endpoints web -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w | tr -d ' ')
[ "${N:-0}" -ge 3 ] || { echo "❌ Service 'web' has $N endpoints, expected 3 (selector must match app=web pods)."; exit 1; }
echo "✅ Service web: ClusterIP 80->8080 with $N endpoints"
exit 0
