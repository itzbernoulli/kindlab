#!/bin/bash
NS=ckad-config
kubectl -n "$NS" get pod cfg-pod >/dev/null 2>&1 || { echo "❌ pod cfg-pod not found in $NS. Create it from busybox:1.36."; exit 1; }
OUT=$(kubectl -n "$NS" exec cfg-pod -- env 2>/dev/null)
COLOR=$(echo "$OUT" | grep '^COLOR=' | cut -d= -f2-)
MODE=$(echo "$OUT" | grep '^APP_MODE=' | cut -d= -f2-)
[ "$COLOR" != "blue" ] && { echo "❌ env COLOR is '${COLOR:-unset}', expected 'blue' (use valueFrom.configMapKeyRef key APP_COLOR)."; exit 1; }
[ "$MODE" != "prod" ] && { echo "❌ env APP_MODE is '${MODE:-unset}', expected 'prod' (import the whole ConfigMap with envFrom.configMapRef app-cfg)."; exit 1; }
echo "✅ cfg-pod has COLOR=blue (configMapKeyRef) and APP_MODE=prod (envFrom)"; exit 0
