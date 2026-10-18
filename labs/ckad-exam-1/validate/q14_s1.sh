#!/bin/bash
NS=exam
SA=$(kubectl -n $NS get serviceaccount app-sa -o jsonpath='{.metadata.name}' 2>/dev/null)
if [ "$SA" != "app-sa" ]; then echo "❌ ServiceAccount 'app-sa' not found in namespace $NS"; exit 1; fi
P=sa-pod
PHASE=$(kubectl -n $NS get pod $P -o jsonpath='{.status.phase}' 2>/dev/null)
if [ -z "$PHASE" ]; then echo "❌ pod '$P' not found in namespace $NS"; exit 1; fi
USED=$(kubectl -n $NS get pod $P -o jsonpath='{.spec.serviceAccountName}' 2>/dev/null)
if [ "$USED" != "app-sa" ]; then echo "❌ pod '$P' must use serviceAccountName app-sa (got '${USED:-default}')"; exit 1; fi
if [ "$PHASE" != "Running" ]; then echo "❌ pod '$P' phase is $PHASE, expected Running"; exit 1; fi
echo "✅ ServiceAccount 'app-sa' exists and pod 'sa-pod' runs under it"; exit 0
