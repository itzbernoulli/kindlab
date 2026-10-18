#!/bin/bash
# Diagnose & fix: the seeded audit-role pointed at the wrong resource. Grade the healthy
# end-state: audit-sa can get/list pods but cannot delete them (still least-privilege).
SA=system:serviceaccount:cks-learn:audit-sa
CAN_LIST=$(kubectl auth can-i list pods --as="$SA" -n cks-learn 2>/dev/null)
CAN_GET=$(kubectl auth can-i get  pods --as="$SA" -n cks-learn 2>/dev/null)
CAN_DEL=$(kubectl auth can-i delete pods --as="$SA" -n cks-learn 2>/dev/null)
if [ "$CAN_LIST" = "yes" ] && [ "$CAN_GET" = "yes" ] && [ "$CAN_DEL" = "no" ]; then
  echo "✅ SA audit-sa can get/list pods but NOT delete pods in cks-learn (Role fault fixed)"; exit 0
fi
if [ "$CAN_LIST" != "yes" ] || [ "$CAN_GET" != "yes" ]; then
  echo "❌ SA audit-sa still cannot get/list pods (list='${CAN_LIST:-no}', get='${CAN_GET:-no}'). Fix the audit-role rule to grant get,list on 'pods' (not the seeded wrong resource)."; exit 1
fi
echo "❌ SA audit-sa can also delete pods (can-i='${CAN_DEL}') — too broad. Grant only get,list on pods."; exit 1
