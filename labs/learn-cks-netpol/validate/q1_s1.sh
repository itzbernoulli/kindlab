#!/bin/bash
NS=netpol-learn
NAME=default-deny-ingress
if ! kubectl -n "$NS" get networkpolicy "$NAME" >/dev/null 2>&1; then
  echo "❌ NetworkPolicy '$NAME' not found in $NS. Create a default-deny-ingress policy with an empty podSelector."; exit 1
fi
ML=$(kubectl -n "$NS" get networkpolicy "$NAME" -o jsonpath='{.spec.podSelector.matchLabels}' 2>/dev/null)
ME=$(kubectl -n "$NS" get networkpolicy "$NAME" -o jsonpath='{.spec.podSelector.matchExpressions}' 2>/dev/null)
if [ -n "$ML" ] || [ -n "$ME" ]; then
  echo "❌ $NAME podSelector is not empty (matchLabels='${ML}', matchExpressions='${ME}'). Use podSelector: {} to select all pods."; exit 1
fi
TYPES=$(kubectl -n "$NS" get networkpolicy "$NAME" -o jsonpath='{.spec.policyTypes}' 2>/dev/null)
if ! echo "$TYPES" | grep -q 'Ingress'; then
  echo "❌ $NAME policyTypes='${TYPES:-none}' must include Ingress."; exit 1
fi
# there must be NO ingress rules (deny-all)
RULES=$(kubectl -n "$NS" get networkpolicy "$NAME" -o jsonpath='{.spec.ingress}' 2>/dev/null)
if [ -n "$RULES" ] && [ "$RULES" != "[]" ]; then
  echo "❌ $NAME has ingress rules ('${RULES}') — a default-deny must have NO ingress rules."; exit 1
fi
echo "✅ $NAME selects all pods and denies all ingress"; exit 0
