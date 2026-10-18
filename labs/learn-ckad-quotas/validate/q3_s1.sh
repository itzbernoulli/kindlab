#!/bin/bash
P=$(kubectl get resourcequota pod-quota -n quota-count -o jsonpath='{.spec.hard.pods}' 2>/dev/null)
if [ "$P" = "2" ]; then echo "✅ pod-quota limits the namespace to 2 pods"; exit 0; fi
echo "❌ pod-quota hard.pods='${P:-none}' (want 2). Run: kubectl create quota pod-quota --hard=pods=2 -n quota-count"; exit 1
