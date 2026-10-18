#!/bin/bash
NS=ingress-learn
kubectl -n "$NS" get ingress web >/dev/null 2>&1 || { echo "❌ Ingress web not found in $NS."; exit 1; }

# collect rule hosts (ignore blank/catch-all entries) and the set of tls hosts
RULE_HOSTS=$(kubectl -n "$NS" get ingress web -o jsonpath='{range .spec.rules[*]}{.host}{"\n"}{end}' 2>/dev/null | grep -v '^$' | sort -u)
TLS_HOSTS=$(kubectl -n "$NS" get ingress web -o jsonpath='{range .spec.tls[*]}{range .hosts[*]}{@}{"\n"}{end}{end}' 2>/dev/null | grep -v '^$' | sort -u)

if [ -z "$RULE_HOSTS" ]; then
  echo "❌ Ingress web has no named rule hosts to protect. Add a rule with host demo.example.com."; exit 1
fi
if [ -z "$TLS_HOSTS" ]; then
  echo "❌ Ingress web has no spec.tls hosts — the routed host is served without TLS. Add a tls hosts entry."; exit 1
fi

# every rule host must appear in the tls host set
MISSING=""
while IFS= read -r h; do
  echo "$TLS_HOSTS" | grep -Fxq "$h" || MISSING="$MISSING $h"
done <<< "$RULE_HOSTS"

if [ -n "$MISSING" ]; then
  echo "❌ Rule host(s) not covered by any spec.tls hosts:$MISSING — they would be served over plain HTTP. Add each to a tls hosts list."; exit 1
fi
echo "✅ every spec.rules host is covered by a spec.tls hosts entry (no plain-HTTP-only host)"; exit 0
