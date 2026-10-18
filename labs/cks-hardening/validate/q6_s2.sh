#!/bin/bash
NS=netpol-lab
NAME=default-deny
if ! kubectl -n "$NS" get networkpolicy "$NAME" >/dev/null 2>&1; then
  echo "❌ NetworkPolicy '$NAME' not found in $NS."; exit 1
fi
TYPES=$(kubectl -n "$NS" get networkpolicy "$NAME" -o jsonpath='{.spec.policyTypes}' 2>/dev/null)
if echo "$TYPES" | grep -q 'Ingress' && echo "$TYPES" | grep -q 'Egress'; then
  echo "✅ $NAME has both Ingress and Egress policyTypes"; exit 0
fi
echo "❌ $NAME policyTypes='${TYPES:-none}' (must include both Ingress and Egress)."; exit 1
