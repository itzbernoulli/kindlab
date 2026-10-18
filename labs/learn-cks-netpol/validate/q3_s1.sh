#!/bin/bash
NS=netpol-learn
NAME=allow-from-monitoring
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
# the from rule must have a namespaceSelector matching kubernetes.io/metadata.name=monitoring
NSNAME=$(kubectl -n "$NS" get networkpolicy "$NAME" -o jsonpath='{.spec.ingress[0].from[0].namespaceSelector.matchLabels.kubernetes\.io/metadata\.name}' 2>/dev/null)
if [ "$NSNAME" != "monitoring" ]; then
  echo "❌ $NAME ingress 'from' must be a namespaceSelector matching kubernetes.io/metadata.name=monitoring (got '${NSNAME:-none}')."; exit 1
fi
echo "✅ $NAME allows ingress to app=web from any pod in namespace monitoring"; exit 0
