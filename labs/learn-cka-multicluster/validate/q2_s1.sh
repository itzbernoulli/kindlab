#!/bin/bash
R=$(kubectl --context "$CTX2" -n prod get deploy api -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "$R" = "2" ]; then echo "✅ Deployment 'api' (2 replicas) in prod on cluster2"; exit 0; fi
echo "❌ create Deployment 'api' (nginx:alpine, 2 replicas) in prod on cluster2 ($CTX2) — got replicas='${R:-none}'"; exit 1
