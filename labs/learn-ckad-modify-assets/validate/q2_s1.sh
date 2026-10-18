#!/bin/bash
NS=modify-learn
if ! kubectl -n $NS get pod tool >/dev/null 2>&1; then echo "❌ pod 'tool' not found in $NS (recreate it with the env var)"; exit 1; fi
V=$(kubectl -n $NS get pod tool -o jsonpath='{.spec.containers[0].env[?(@.name=="MODE")].value}' 2>/dev/null)
PH=$(kubectl -n $NS get pod tool -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$V" != "prod" ]; then echo "❌ pod 'tool' has no env MODE=prod (got '${V:-none}'). A running Pod's env is immutable — recreate it (kubectl get pod tool -o yaml > p.yaml; add env; kubectl replace --force -f p.yaml)"; exit 1; fi
if [ "$PH" != "Running" ]; then echo "❌ pod 'tool' is '${PH}', not Running"; exit 1; fi
echo "✅ pod 'tool' now has env MODE=prod (required recreating it — pods are immutable in place)"; exit 0
