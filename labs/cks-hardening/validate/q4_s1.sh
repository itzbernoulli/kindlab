#!/bin/bash
SA="system:serviceaccount:rbac-lab:reader"
CAN=$(kubectl auth can-i list pods --as="$SA" -n rbac-lab 2>/dev/null)
if [ "$CAN" = "yes" ]; then
  echo "✅ $SA CAN list pods in rbac-lab"; exit 0
fi
echo "❌ $SA cannot list pods in rbac-lab (can-i='${CAN:-no}'). Create a Role (get,list pods) + RoleBinding to the reader SA."; exit 1
