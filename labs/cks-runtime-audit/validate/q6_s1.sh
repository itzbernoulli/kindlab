#!/bin/bash
V=$(kubectl get sa restricted -n default -o jsonpath='{.automountServiceAccountToken}' 2>/dev/null)
if [ "$V" = "false" ]; then echo "✅ ServiceAccount 'restricted' has automountServiceAccountToken: false"; exit 0; fi
echo "❌ ServiceAccount 'restricted' automountServiceAccountToken='${V:-unset}' (expected false)"; exit 1
