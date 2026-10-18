#!/bin/bash
NS=cks-podsec
P=secure-app
kubectl -n "$NS" get pod "$P" >/dev/null 2>&1 || { echo "❌ pod $P not found in $NS. Create it from busybox:1.36 running 'sleep 3600'."; exit 1; }
PHASE=$(kubectl -n "$NS" get pod "$P" -o jsonpath='{.status.phase}' 2>/dev/null)
NONROOT=$(kubectl -n "$NS" get pod "$P" -o jsonpath='{.spec.containers[0].securityContext.runAsNonRoot}' 2>/dev/null)
RUID=$(kubectl -n "$NS" get pod "$P" -o jsonpath='{.spec.containers[0].securityContext.runAsUser}' 2>/dev/null)
[ -z "$NONROOT" ] && NONROOT=$(kubectl -n "$NS" get pod "$P" -o jsonpath='{.spec.securityContext.runAsNonRoot}' 2>/dev/null)
[ -z "$RUID" ] && RUID=$(kubectl -n "$NS" get pod "$P" -o jsonpath='{.spec.securityContext.runAsUser}' 2>/dev/null)
[ "$NONROOT" = "true" ] || { echo "❌ runAsNonRoot is not true (got '${NONROOT:-unset}'). Set securityContext.runAsNonRoot: true."; exit 1; }
[ "$RUID" = "1000" ] || { echo "❌ runAsUser is not 1000 (got '${RUID:-unset}'). Set securityContext.runAsUser: 1000."; exit 1; }
[ "$PHASE" = "Running" ] || { echo "❌ pod phase is '${PHASE:-unknown}', not Running. Use 'sleep 3600' so it stays up."; exit 1; }
echo "✅ secure-app runs non-root as UID 1000"
exit 0
