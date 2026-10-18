#!/bin/bash
V=$(kubectl --context "$CTX" -n default get configmap shared-cfg -o jsonpath='{.data.env}' 2>/dev/null)
ON2=$(kubectl --context "$CTX2" -n default get configmap shared-cfg -o name 2>/dev/null)
if [ "$V" = "prod" ] && [ -z "$ON2" ]; then echo "✅ configmap 'shared-cfg' (env=prod) on cluster1 only"; exit 0; fi
if [ "$V" != "prod" ]; then echo "❌ create configmap 'shared-cfg' (env=prod) in default on cluster1 ($CTX)"; exit 1; fi
echo "❌ shared-cfg also on cluster2 default — step 3 is cluster1 only"; exit 1
