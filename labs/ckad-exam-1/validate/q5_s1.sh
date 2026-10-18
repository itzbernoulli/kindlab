#!/bin/bash
NS=exam
CM=$(kubectl -n $NS get configmap app-cfg -o jsonpath='{.data.APP_MODE}' 2>/dev/null)
if [ "$CM" != "production" ]; then echo "❌ ConfigMap app-cfg key APP_MODE must equal 'production' (got '${CM:-none}')"; exit 1; fi
SEC=$(kubectl -n $NS get secret app-sec -o jsonpath='{.data.API_KEY}' 2>/dev/null | base64 -d 2>/dev/null)
if [ "$SEC" != "s3cr3t" ]; then echo "❌ Secret app-sec key API_KEY must equal 's3cr3t'"; exit 1; fi
echo "✅ ConfigMap app-cfg and Secret app-sec have the required keys/values"; exit 0
