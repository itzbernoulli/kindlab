#!/bin/bash
A=$(kubectl -n pod-design get deploy diag -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if ! kubectl -n pod-design get deploy diag >/dev/null 2>&1; then echo "❌ Deployment 'diag' not found (don't delete it — fix it)"; exit 1; fi
if [ "${A:-0}" -ge 1 ] 2>/dev/null; then echo "✅ Deployment diag has ${A} available replica(s) — readiness fault fixed"; exit 0; fi
echo "❌ Deployment diag has 0 available replicas — the readiness probe is still failing (check its port vs what nginx serves)"; exit 1
