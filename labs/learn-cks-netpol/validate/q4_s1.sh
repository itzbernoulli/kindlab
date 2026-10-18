#!/bin/bash
NS=netpol-learn
NAME=default-deny-egress-allow-dns
if ! kubectl -n "$NS" get networkpolicy "$NAME" >/dev/null 2>&1; then
  echo "❌ NetworkPolicy '$NAME' not found in $NS."; exit 1
fi
# selects all pods (empty podSelector)
ML=$(kubectl -n "$NS" get networkpolicy "$NAME" -o jsonpath='{.spec.podSelector.matchLabels}' 2>/dev/null)
ME=$(kubectl -n "$NS" get networkpolicy "$NAME" -o jsonpath='{.spec.podSelector.matchExpressions}' 2>/dev/null)
if [ -n "$ML" ] || [ -n "$ME" ]; then
  echo "❌ $NAME podSelector must be empty ({}) to select all pods (matchLabels='${ML}')."; exit 1
fi
# egress isolated
if ! kubectl -n "$NS" get networkpolicy "$NAME" -o jsonpath='{.spec.policyTypes}' 2>/dev/null | grep -q 'Egress'; then
  echo "❌ $NAME policyTypes must include Egress."; exit 1
fi
# DNS to kube-system
NSNAME=$(kubectl -n "$NS" get networkpolicy "$NAME" -o jsonpath='{.spec.egress[0].to[0].namespaceSelector.matchLabels.kubernetes\.io/metadata\.name}' 2>/dev/null)
if [ "$NSNAME" != "kube-system" ]; then
  echo "❌ $NAME egress 'to' must be a namespaceSelector matching kubernetes.io/metadata.name=kube-system (got '${NSNAME:-none}')."; exit 1
fi
PORTS=$(kubectl -n "$NS" get networkpolicy "$NAME" -o jsonpath='{range .spec.egress[0].ports[*]}{.protocol}/{.port} {end}' 2>/dev/null)
if ! echo "$PORTS" | grep -q 'UDP/53'; then
  echo "❌ $NAME egress must allow UDP port 53 for DNS (ports='${PORTS:-none}')."; exit 1
fi
if ! echo "$PORTS" | grep -q 'TCP/53'; then
  echo "❌ $NAME egress must also allow TCP port 53 for DNS (ports='${PORTS:-none}')."; exit 1
fi
echo "✅ $NAME is egress-isolated for all pods and allows DNS (UDP+TCP 53) to kube-system"; exit 0
