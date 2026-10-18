#!/bin/bash
NS=ckad-config
kubectl -n "$NS" get pod sec-pod >/dev/null 2>&1 || { echo "❌ pod sec-pod not found in $NS. Create it from busybox:1.36."; exit 1; }
PASS=$(kubectl -n "$NS" exec sec-pod -- sh -c 'printf %s "$DB_PASS"' 2>/dev/null)
[ "$PASS" != "s3cr3t" ] && { echo "❌ env DB_PASS is '${PASS:-unset}', expected 's3cr3t' (use valueFrom.secretKeyRef key DB_PASS)."; exit 1; }
USER=$(kubectl -n "$NS" exec sec-pod -- cat /etc/creds/DB_USER 2>/dev/null)
[ "$USER" != "admin" ] && { echo "❌ /etc/creds/DB_USER is '${USER:-missing}', expected 'admin' (mount Secret db-cred as a volume at /etc/creds)."; exit 1; }
echo "✅ sec-pod exposes DB_PASS=s3cr3t and mounts /etc/creds/DB_USER=admin"; exit 0
