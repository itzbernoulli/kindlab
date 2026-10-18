#!/bin/bash
NS=cks-podsec
P=seccomp-app
kubectl -n "$NS" get pod "$P" >/dev/null 2>&1 || { echo "❌ pod $P not found in $NS. Create it from busybox:1.36 running 'sleep 3600'."; exit 1; }
PHASE=$(kubectl -n "$NS" get pod "$P" -o jsonpath='{.status.phase}' 2>/dev/null)
T=$(kubectl -n "$NS" get pod "$P" -o jsonpath='{.spec.securityContext.seccompProfile.type}' 2>/dev/null)
[ -z "$T" ] && T=$(kubectl -n "$NS" get pod "$P" -o jsonpath='{.spec.containers[0].securityContext.seccompProfile.type}' 2>/dev/null)
[ "$T" = "RuntimeDefault" ] || { echo "❌ seccompProfile.type is '${T:-unset}', expected RuntimeDefault. Set securityContext.seccompProfile.type: RuntimeDefault."; exit 1; }
[ "$PHASE" = "Running" ] || { echo "❌ pod phase is '${PHASE:-unknown}', not Running."; exit 1; }
echo "✅ seccomp-app uses seccompProfile RuntimeDefault"
exit 0
