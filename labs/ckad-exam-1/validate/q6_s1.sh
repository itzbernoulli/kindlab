#!/bin/bash
NS=exam
P=limited
PHASE=$(kubectl -n $NS get pod $P -o jsonpath='{.status.phase}' 2>/dev/null)
if [ -z "$PHASE" ]; then echo "❌ pod '$P' not found in namespace $NS"; exit 1; fi
RC=$(kubectl -n $NS get pod $P -o jsonpath='{.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
RM=$(kubectl -n $NS get pod $P -o jsonpath='{.spec.containers[0].resources.requests.memory}' 2>/dev/null)
LC=$(kubectl -n $NS get pod $P -o jsonpath='{.spec.containers[0].resources.limits.cpu}' 2>/dev/null)
LM=$(kubectl -n $NS get pod $P -o jsonpath='{.spec.containers[0].resources.limits.memory}' 2>/dev/null)
if [ "$RC" != "100m" ] || [ "$RM" != "64Mi" ]; then echo "❌ requests must be cpu=100m memory=64Mi (got cpu=$RC mem=$RM)"; exit 1; fi
if [ "$LC" != "250m" ] || [ "$LM" != "128Mi" ]; then echo "❌ limits must be cpu=250m memory=128Mi (got cpu=$LC mem=$LM)"; exit 1; fi
if [ "$PHASE" != "Running" ]; then echo "❌ pod '$P' phase is $PHASE, expected Running"; exit 1; fi
echo "✅ pod 'limited' has the exact requests/limits and is Running"; exit 0
