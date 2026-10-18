#!/bin/bash
NS=exam
SPEC=$(kubectl -n $NS get deploy web -o jsonpath='{.spec.replicas}' 2>/dev/null)
AVAIL=$(kubectl -n $NS get deploy web -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ -z "$SPEC" ]; then echo "❌ Deployment 'web' not found in namespace $NS"; exit 1; fi
if [ "$SPEC" != "6" ]; then echo "❌ spec.replicas is '$SPEC', expected 6 (scale it)"; exit 1; fi
if [ "${AVAIL:-0}" != "6" ]; then echo "❌ only ${AVAIL:-0}/6 replicas available"; exit 1; fi
echo "✅ Deployment 'web' scaled to 6 available replicas"; exit 0
