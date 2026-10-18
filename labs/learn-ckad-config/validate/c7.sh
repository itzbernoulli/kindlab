#!/bin/bash
kubectl -n ckad-config get pod brokencfg >/dev/null 2>&1 || { echo "❌ pod 'brokencfg' not found (don't delete it — fix the ConfigMap)"; exit 1; }
PH=$(kubectl -n ckad-config get pod brokencfg -o jsonpath='{.status.phase}' 2>/dev/null)
[ "$PH" = "Running" ] || { echo "❌ brokencfg is '${PH}', not Running — it's stuck on a missing ConfigMap key. describe it, then add the key to app-config"; exit 1; }
echo "✅ brokencfg is Running (fixed the missing ConfigMap key at the source)"; exit 0
