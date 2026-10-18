#!/bin/bash
# Step 6: Role log-reader grants get on pods/log (subresource) + bound to dev.
CAN=$(kubectl auth can-i get pods/log --as=dev -n rbac-learn 2>/dev/null)
[ "$CAN" = "yes" ] || { echo "❌ dev cannot get pods/log (can-i='${CAN:-no}'). Create Role log-reader (--resource=pods/log) + RoleBinding dev-log to dev."; exit 1; }

J=$(kubectl -n rbac-learn get role log-reader -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Role 'log-reader' not found in rbac-learn"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
r=json.loads(os.environ['J'])
ok=False
for rule in (r.get("rules") or []):
    res=set(rule.get("resources") or [])
    verbs=set(rule.get("verbs") or [])
    if "pods/log" in res and "get" in verbs:
        ok=True
if not ok: fail("Role log-reader must allow get on the subresource pods/log")
print("✅ Role log-reader grants get on pods/log, bound to dev")
PY
