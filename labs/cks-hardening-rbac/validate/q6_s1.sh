#!/bin/bash
SA=system:serviceaccount:cks-learn:reader
CAN_LIST=$(kubectl auth can-i list   pods --as="$SA" -n cks-learn 2>/dev/null)
CAN_DEL=$(kubectl auth can-i delete pods --as="$SA" -n cks-learn 2>/dev/null)
if [ "$CAN_LIST" = "yes" ] && [ "$CAN_DEL" = "no" ]; then
  echo "✅ SA reader can list pods but NOT delete pods in cks-learn (least privilege)"; exit 0
fi
if [ "$CAN_LIST" != "yes" ]; then
  echo "❌ SA reader cannot list pods yet (can-i='${CAN_LIST:-no}'). Create a Role (get,list on pods) + RoleBinding to serviceaccount cks-learn:reader."; exit 1
fi
echo "❌ SA reader can also delete pods (can-i='${CAN_DEL}') — too broad. Grant only get,list on pods."; exit 1
