#!/bin/bash
NS=ingress-learn
kubectl -n "$NS" get ingress web >/dev/null 2>&1 || { echo "❌ Ingress web not found in $NS."; exit 1; }
# locate the rule for demo.example.com and inspect its backend service name + port
SVC=$(kubectl -n "$NS" get ingress web -o jsonpath='{range .spec.rules[?(@.host=="demo.example.com")]}{range .http.paths[*]}{.backend.service.name}{":"}{.backend.service.port.number}{"\n"}{end}{end}' 2>/dev/null)
if [ -z "$SVC" ]; then
  echo "❌ Ingress web has no rule for host demo.example.com (or no http paths). Add a rule routing that host."; exit 1
fi
if echo "$SVC" | grep -Fxq "web:80"; then
  echo "✅ Ingress rule host demo.example.com routes to service web port 80"; exit 0
fi
echo "❌ Rule for demo.example.com does not route to service web:80 (found '$(echo "$SVC" | tr '\n' ' ')'). Set backend.service.name=web, port.number=80."; exit 1
