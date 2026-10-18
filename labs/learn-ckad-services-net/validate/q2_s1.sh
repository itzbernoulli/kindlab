#!/bin/bash
NS=svcnet-learn
TYPE=$(kubectl -n $NS get svc web-np -o jsonpath='{.spec.type}' 2>/dev/null)
[ -n "$TYPE" ] || { echo "❌ Service 'web-np' not found in $NS. Create a NodePort Service named web-np."; exit 1; }
[ "$TYPE" = "NodePort" ] || { echo "❌ Service 'web-np' type is '$TYPE', expected NodePort."; exit 1; }
PORT=$(kubectl -n $NS get svc web-np -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
TP=$(kubectl -n $NS get svc web-np -o jsonpath='{.spec.ports[0].targetPort}' 2>/dev/null)
NP=$(kubectl -n $NS get svc web-np -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
[ "$PORT" = "80" ] || { echo "❌ Service 'web-np' port is '$PORT', expected 80."; exit 1; }
[ "$TP" = "8080" ] || { echo "❌ Service 'web-np' targetPort is '$TP', expected 8080."; exit 1; }
[ "$NP" = "30080" ] || { echo "❌ Service 'web-np' nodePort is '$NP', expected 30080."; exit 1; }
N=$(kubectl -n $NS get endpoints web-np -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w | tr -d ' ')
[ "${N:-0}" -ge 1 ] || { echo "❌ Service 'web-np' has no endpoints (selector must match app=web pods)."; exit 1; }
echo "✅ Service web-np: NodePort 30080 -> targetPort 8080 with $N endpoints"
exit 0
