#!/bin/bash
NS=netpol-lab
NAME=default-deny
# Empty podSelector => selects all pods. jsonpath of {} serializes to 'map[]' via
# -o jsonpath for the whole object; instead check that spec.podSelector has no
# matchLabels and no matchExpressions.
if ! kubectl -n "$NS" get networkpolicy "$NAME" >/dev/null 2>&1; then
  echo "❌ NetworkPolicy '$NAME' not found in $NS. Create a default-deny policy with an empty podSelector."; exit 1
fi
ML=$(kubectl -n "$NS" get networkpolicy "$NAME" -o jsonpath='{.spec.podSelector.matchLabels}' 2>/dev/null)
ME=$(kubectl -n "$NS" get networkpolicy "$NAME" -o jsonpath='{.spec.podSelector.matchExpressions}' 2>/dev/null)
if [ -z "$ML" ] && [ -z "$ME" ]; then
  echo "✅ $NAME selects all pods (empty podSelector) in $NS"; exit 0
fi
echo "❌ $NAME podSelector is not empty (matchLabels='${ML}', matchExpressions='${ME}'). Use spec.podSelector: {} to select all pods."; exit 1
