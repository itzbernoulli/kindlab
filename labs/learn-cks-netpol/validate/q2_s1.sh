#!/bin/bash
NS=netpol-learn
NAME=allow-from-client
if ! kubectl -n "$NS" get networkpolicy "$NAME" >/dev/null 2>&1; then
  echo "❌ NetworkPolicy '$NAME' not found in $NS."; exit 1
fi
TGT=$(kubectl -n "$NS" get networkpolicy "$NAME" -o jsonpath='{.spec.podSelector.matchLabels.app}' 2>/dev/null)
if [ "$TGT" != "web" ]; then
  echo "❌ $NAME must target pods with app=web (got app='${TGT:-none}')."; exit 1
fi
if ! kubectl -n "$NS" get networkpolicy "$NAME" -o jsonpath='{.spec.policyTypes}' 2>/dev/null | grep -q 'Ingress'; then
  echo "❌ $NAME policyTypes must include Ingress."; exit 1
fi
# the from rule must have a podSelector matching role=client
SRC=$(kubectl -n "$NS" get networkpolicy "$NAME" -o jsonpath='{.spec.ingress[0].from[0].podSelector.matchLabels.role}' 2>/dev/null)
if [ "$SRC" != "client" ]; then
  echo "❌ $NAME ingress 'from' must be a podSelector matching role=client (got role='${SRC:-none}')."; exit 1
fi
# must NOT also allow from an unrestricted namespaceSelector or ipBlock in the same entry
NSSEL=$(kubectl -n "$NS" get networkpolicy "$NAME" -o jsonpath='{.spec.ingress[0].from[0].namespaceSelector}' 2>/dev/null)
if [ -n "$NSSEL" ]; then
  echo "❌ $NAME 'from' entry also has a namespaceSelector ('${NSSEL}') — this step wants podSelector only."; exit 1
fi
echo "✅ $NAME allows ingress to app=web only from pods with role=client"; exit 0
