#!/bin/bash
NS=lr-minmax
MAX=$(kubectl get limitrange constraints -n $NS -o jsonpath='{.spec.limits[0].max.cpu}' 2>/dev/null)
MIN=$(kubectl get limitrange constraints -n $NS -o jsonpath='{.spec.limits[0].min.cpu}' 2>/dev/null)
if [ "$MAX" = "1" ] && [ "$MIN" = "100m" ]; then echo "✅ constraints LimitRange: min.cpu=100m, max.cpu=1"; exit 0; fi
echo "❌ constraints min/max off (min.cpu='${MIN:-none}' max.cpu='${MAX:-none}'; want 100m/1)"; exit 1
