#!/bin/bash
C=$(kubectl auth can-i list pods --as=dev -n rbac-learn 2>/dev/null)
[ "$C" = "yes" ] && { echo "✅ dev can list pods in rbac-learn"; exit 0; }
echo "❌ dev cannot list pods (can-i='${C:-no}'). Create Role pod-reader + RoleBinding to user dev."; exit 1
