#!/bin/bash
NS=svcnet-learn
kubectl -n $NS get ingress web-ing >/dev/null 2>&1 || { echo "❌ Ingress 'web-ing' not found in $NS."; exit 1; }
HOST=$(kubectl -n $NS get ingress web-ing -o jsonpath='{.spec.rules[0].host}' 2>/dev/null)
[ "$HOST" = "web.example.com" ] || { echo "❌ Ingress host is '$HOST', expected web.example.com."; exit 1; }
PATH_V=$(kubectl -n $NS get ingress web-ing -o jsonpath='{.spec.rules[0].http.paths[0].path}' 2>/dev/null)
[ "$PATH_V" = "/" ] || { echo "❌ Ingress path is '$PATH_V', expected /."; exit 1; }
PT=$(kubectl -n $NS get ingress web-ing -o jsonpath='{.spec.rules[0].http.paths[0].pathType}' 2>/dev/null)
[ "$PT" = "Prefix" ] || { echo "❌ Ingress pathType is '$PT', expected Prefix."; exit 1; }
SVC=$(kubectl -n $NS get ingress web-ing -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}' 2>/dev/null)
[ "$SVC" = "web" ] || { echo "❌ Ingress backend service is '$SVC', expected web."; exit 1; }
SP=$(kubectl -n $NS get ingress web-ing -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.port.number}' 2>/dev/null)
[ "$SP" = "80" ] || { echo "❌ Ingress backend service port is '$SP', expected 80."; exit 1; }
echo "✅ Ingress web-ing: web.example.com / (Prefix) -> web:80"
exit 0
