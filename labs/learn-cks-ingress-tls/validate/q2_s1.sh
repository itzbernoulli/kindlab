#!/bin/bash
NS=ingress-learn
kubectl -n "$NS" get ingress web >/dev/null 2>&1 || { echo "❌ Ingress web not found in $NS. Create it with a spec.tls block referencing web-tls."; exit 1; }
# find the tls entry whose secretName is web-tls
SN=$(kubectl -n "$NS" get ingress web -o jsonpath='{range .spec.tls[*]}{.secretName}{"\n"}{end}' 2>/dev/null | grep -Fx "web-tls")
if [ -z "$SN" ]; then
  echo "❌ Ingress web has no spec.tls entry with secretName=web-tls. Add tls: [{hosts:[demo.example.com], secretName: web-tls}]."; exit 1
fi
# the web-tls tls entry must list host demo.example.com
HOST=$(kubectl -n "$NS" get ingress web -o jsonpath='{range .spec.tls[?(@.secretName=="web-tls")]}{range .hosts[*]}{@}{"\n"}{end}{end}' 2>/dev/null | grep -Fx "demo.example.com")
if [ -z "$HOST" ]; then
  echo "❌ The web-tls tls entry does not list host demo.example.com. Set hosts: [demo.example.com]."; exit 1
fi
echo "✅ Ingress web spec.tls references secretName web-tls for host demo.example.com"; exit 0
