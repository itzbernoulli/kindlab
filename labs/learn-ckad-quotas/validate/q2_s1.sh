#!/bin/bash
NS=quota-compute
PH=$(kubectl get pod app -n $NS -o jsonpath='{.status.phase}' 2>/dev/null)
RC=$(kubectl get pod app -n $NS -o jsonpath='{.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
if [ "$PH" = "Running" ] && [ -n "$RC" ]; then echo "✅ pod 'app' Running with requests (cpu=$RC)"; exit 0; fi
echo "❌ pod 'app' must be Running with resource requests set (phase='${PH:-none}' requests.cpu='${RC:-none}'). The quota forces requests+limits."; exit 1
