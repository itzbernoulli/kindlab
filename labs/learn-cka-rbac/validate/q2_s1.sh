#!/bin/bash
C=$(kubectl auth can-i list nodes --as=dev 2>/dev/null)
[ "$C" = "yes" ] && { echo "✅ dev can list nodes (cluster-scoped)"; exit 0; }
echo "❌ dev cannot list nodes (can-i='${C:-no}'). Nodes are cluster-scoped — use ClusterRole + ClusterRoleBinding."; exit 1
