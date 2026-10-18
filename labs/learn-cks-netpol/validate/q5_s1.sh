#!/bin/bash
NS=netpol-learn
NAME=allow-egress-to-db
if ! kubectl -n "$NS" get networkpolicy "$NAME" >/dev/null 2>&1; then
  echo "❌ NetworkPolicy '$NAME' not found in $NS."; exit 1
fi
TGT=$(kubectl -n "$NS" get networkpolicy "$NAME" -o jsonpath='{.spec.podSelector.matchLabels.app}' 2>/dev/null)
if [ "$TGT" != "web" ]; then
  echo "❌ $NAME must target pods with app=web (got app='${TGT:-none}')."; exit 1
fi
if ! kubectl -n "$NS" get networkpolicy "$NAME" -o jsonpath='{.spec.policyTypes}' 2>/dev/null | grep -q 'Egress'; then
  echo "❌ $NAME policyTypes must include Egress."; exit 1
fi
DST=$(kubectl -n "$NS" get networkpolicy "$NAME" -o jsonpath='{.spec.egress[0].to[0].podSelector.matchLabels.app}' 2>/dev/null)
if [ "$DST" != "db" ]; then
  echo "❌ $NAME egress 'to' must be a podSelector matching app=db (got app='${DST:-none}')."; exit 1
fi
PROTO=$(kubectl -n "$NS" get networkpolicy "$NAME" -o jsonpath='{.spec.egress[0].ports[0].protocol}' 2>/dev/null)
PORT=$(kubectl -n "$NS" get networkpolicy "$NAME" -o jsonpath='{.spec.egress[0].ports[0].port}' 2>/dev/null)
if [ "$PROTO" != "TCP" ] || [ "$PORT" != "5432" ]; then
  echo "❌ $NAME egress must allow TCP port 5432 (got protocol='${PROTO:-none}' port='${PORT:-none}')."; exit 1
fi
echo "✅ $NAME allows egress from app=web only to app=db on TCP/5432"; exit 0
