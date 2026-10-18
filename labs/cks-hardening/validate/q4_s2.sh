#!/bin/bash
SA="system:serviceaccount:rbac-lab:reader"
LIST=$(kubectl auth can-i list pods --as="$SA" -n rbac-lab 2>/dev/null)
DEL=$(kubectl auth can-i delete pods --as="$SA" -n rbac-lab 2>/dev/null)
if [ "$LIST" = "yes" ] && [ "$DEL" = "no" ]; then
  echo "✅ $SA can list but NOT delete pods (least privilege)"; exit 0
fi
if [ "$LIST" != "yes" ]; then
  echo "❌ least privilege not in place: reader cannot list pods yet. Bind a get/list Role first."; exit 1
fi
echo "❌ reader CAN delete pods (can-i='${DEL}') — too permissive. Grant only get/list on pods."; exit 1
