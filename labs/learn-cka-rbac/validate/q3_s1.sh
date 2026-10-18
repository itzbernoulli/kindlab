#!/bin/bash
SA=system:serviceaccount:rbac-learn:ci
C=$(kubectl auth can-i list pods --as="$SA" -n rbac-learn 2>/dev/null)
[ "$C" = "yes" ] && { echo "✅ ServiceAccount ci can list pods"; exit 0; }
echo "❌ SA ci cannot list pods (can-i='${C:-no}'). Create sa 'ci' and bind the pod-reader Role to it."; exit 1
