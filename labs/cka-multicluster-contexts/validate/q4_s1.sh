#!/bin/bash
V=$(kubectl --context "$CTX2" -n prod get configmap shared-cfg -o jsonpath='{.data.env}' 2>/dev/null)
if [ "$V" = "prod" ]; then echo "✅ shared-cfg (env=prod) exists in prod on cluster2 ($CTX2)"; exit 0; fi
echo "❌ create shared-cfg (env=prod) in prod on cluster2: kubectl --context $CTX2 -n prod create configmap shared-cfg --from-literal=env=prod — got env='${V:-none}'"; exit 1
