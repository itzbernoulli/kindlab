#!/bin/bash
NS=cks-podsec
P=ro-app
kubectl -n "$NS" get pod "$P" >/dev/null 2>&1 || { echo "❌ pod $P not found in $NS. Create it from busybox:1.36 running 'sleep 3600'."; exit 1; }
PHASE=$(kubectl -n "$NS" get pod "$P" -o jsonpath='{.status.phase}' 2>/dev/null)
RO=$(kubectl -n "$NS" get pod "$P" -o jsonpath='{.spec.containers[0].securityContext.readOnlyRootFilesystem}' 2>/dev/null)
MP=$(kubectl -n "$NS" get pod "$P" -o jsonpath='{range .spec.containers[0].volumeMounts[*]}{.mountPath}{"\n"}{end}' 2>/dev/null)
VNAME=$(kubectl -n "$NS" get pod "$P" -o jsonpath='{range .spec.containers[0].volumeMounts[?(@.mountPath=="/tmp")]}{.name}{end}' 2>/dev/null)
ED=$(kubectl -n "$NS" get pod "$P" -o jsonpath="{range .spec.volumes[?(@.name=='$VNAME')]}{.emptyDir}{end}" 2>/dev/null)
[ "$RO" = "true" ] || { echo "❌ readOnlyRootFilesystem is not true (got '${RO:-unset}'). Set securityContext.readOnlyRootFilesystem: true."; exit 1; }
echo "$MP" | grep -qx "/tmp" || { echo "❌ no volumeMount at /tmp. Mount a writable volume at /tmp so the pod can run."; exit 1; }
[ -n "$VNAME" ] && [ -n "$ED" ] || { echo "❌ the /tmp mount is not backed by an emptyDir volume. Add volumes: [{name: tmp, emptyDir: {}}]."; exit 1; }
[ "$PHASE" = "Running" ] || { echo "❌ pod phase is '${PHASE:-unknown}', not Running."; exit 1; }
echo "✅ ro-app has a read-only root fs with an emptyDir at /tmp and is Running"
exit 0
