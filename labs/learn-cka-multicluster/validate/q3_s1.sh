#!/bin/bash
V=$(kubectl --context "$CTX" -n default get configmap shared-cfg -o jsonpath='{.data.env}' 2>/dev/null)
ON2=$(kubectl --context "$CTX2" -n default get configmap shared-cfg -o name 2>/dev/null)
if [ "$V" != "prod" ]; then echo "❌ create configmap 'shared-cfg' with env=prod in default on cluster1 ($CTX) — got env='${V:-none}'"; exit 1; fi
if [ -n "$ON2" ]; then echo "❌ shared-cfg also exists in default on cluster2 — step 3 is cluster1 only (wrong context)"; exit 1; fi
echo "✅ configmap 'shared-cfg' (env=prod) in default on cluster1 only"
