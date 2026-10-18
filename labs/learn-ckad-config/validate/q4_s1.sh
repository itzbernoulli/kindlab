#!/bin/bash
NS=ckad-config
kubectl -n "$NS" get pod sctx-pod >/dev/null 2>&1 || { echo "❌ pod sctx-pod not found in $NS. Create it from busybox:1.36."; exit 1; }
NONROOT=$(kubectl -n "$NS" get pod sctx-pod -o jsonpath='{.spec.containers[0].securityContext.runAsNonRoot}' 2>/dev/null)
UID_SET=$(kubectl -n "$NS" get pod sctx-pod -o jsonpath='{.spec.containers[0].securityContext.runAsUser}' 2>/dev/null)
DROP=$(kubectl -n "$NS" get pod sctx-pod -o jsonpath='{.spec.containers[0].securityContext.capabilities.drop}' 2>/dev/null)
[ "$NONROOT" != "true" ] && { echo "❌ container securityContext.runAsNonRoot is '${NONROOT:-unset}', expected 'true'."; exit 1; }
[ "$UID_SET" != "1000" ] && { echo "❌ container securityContext.runAsUser is '${UID_SET:-unset}', expected '1000'."; exit 1; }
echo "$DROP" | grep -q "ALL" || { echo "❌ capabilities.drop is '${DROP:-unset}', expected it to include 'ALL'."; exit 1; }
RUID=$(kubectl -n "$NS" exec sctx-pod -- id -u 2>/dev/null)
[ "$RUID" != "1000" ] && { echo "❌ pod is running as UID '${RUID:-unknown}', expected 1000."; exit 1; }
echo "✅ sctx-pod runs as UID 1000 (non-root) with ALL capabilities dropped"; exit 0
