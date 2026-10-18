#!/bin/bash
NS=lr-defaults
RC=$(kubectl get pod nodefaults -n $NS -o jsonpath='{.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
LC=$(kubectl get pod nodefaults -n $NS -o jsonpath='{.spec.containers[0].resources.limits.cpu}' 2>/dev/null)
if [ "$RC" = "200m" ] && [ "$LC" = "500m" ]; then echo "✅ nodefaults got LimitRange defaults (requests.cpu=200m, limits.cpu=500m)"; exit 0; fi
echo "❌ nodefaults didn't inherit the LimitRange defaults (requests.cpu='${RC:-none}' limits.cpu='${LC:-none}'; want 200m/500m). Create the LimitRange BEFORE the pod."; exit 1
