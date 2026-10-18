#!/bin/bash
# Step 1: Role pod-reader (get,list,watch pods) + RoleBinding to user dev.
# Positive: dev can list pods. Negative: dev canNOT delete pods (verbs are exact).
CAN=$(kubectl auth can-i list pods --as=dev -n rbac-learn 2>/dev/null)
[ "$CAN" = "yes" ] || { echo "❌ dev cannot list pods (can-i='${CAN:-no}'). Create Role pod-reader + RoleBinding dev-pr to user dev."; exit 1; }
DEL=$(kubectl auth can-i delete pods --as=dev -n rbac-learn 2>/dev/null)
[ "$DEL" = "no" ] || { echo "❌ dev can also DELETE pods (can-i='${DEL}') — too broad. pod-reader must allow only get,list,watch."; exit 1; }

J=$(kubectl -n rbac-learn get role pod-reader -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Role 'pod-reader' not found in rbac-learn"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
r=json.loads(os.environ['J'])
def fail(m): print("❌ "+m); sys.exit(1)
ok=False
for rule in (r.get("rules") or []):
    groups=rule.get("apiGroups") or []
    res=set(rule.get("resources") or [])
    verbs=set(rule.get("verbs") or [])
    if "pods" in res and ("" in groups or "*" in groups) and {"get","list","watch"}<=verbs:
        ok=True
if not ok: fail("Role pod-reader must allow get,list,watch on pods (core apiGroup \"\")")
print("✅ Role pod-reader (get,list,watch pods) bound to dev; dev can list but not delete pods")
PY
