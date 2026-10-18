#!/bin/bash
NS=cks-podsec
P=cap-app
kubectl -n "$NS" get pod "$P" >/dev/null 2>&1 || { echo "❌ pod $P not found in $NS. Create it from busybox:1.36 running 'sleep 3600'."; exit 1; }
PHASE=$(kubectl -n "$NS" get pod "$P" -o jsonpath='{.status.phase}' 2>/dev/null)
DROP=$(kubectl -n "$NS" get pod "$P" -o jsonpath='{.spec.containers[0].securityContext.capabilities.drop[*]}' 2>/dev/null)
ADD=$(kubectl -n "$NS" get pod "$P" -o jsonpath='{.spec.containers[0].securityContext.capabilities.add[*]}' 2>/dev/null)
echo "$DROP" | tr ' ' '\n' | grep -qx "ALL" || { echo "❌ capabilities.drop does not include ALL (got '${DROP:-none}'). Set drop: [\"ALL\"]."; exit 1; }
[ "$ADD" = "NET_BIND_SERVICE" ] || { echo "❌ capabilities.add must be exactly [NET_BIND_SERVICE] (got '${ADD:-none}'). Add only NET_BIND_SERVICE."; exit 1; }
[ "$PHASE" = "Running" ] || { echo "❌ pod phase is '${PHASE:-unknown}', not Running."; exit 1; }
echo "✅ cap-app drops ALL and adds only NET_BIND_SERVICE"
exit 0
