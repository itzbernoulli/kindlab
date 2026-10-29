#!/bin/bash
# Step 3: ServiceAccount ci exists + RoleBinding ci-pr binds pod-reader to it.
CAN=$(kubectl auth can-i list pods --as=system:serviceaccount:rbac-learn:ci -n rbac-learn 2>/dev/null)
[ "$CAN" = "yes" ] || { echo "❌ SA ci cannot list pods (can-i='${CAN:-no}'). Create sa ci + RoleBinding ci-pr to pod-reader."; exit 1; }

kubectl -n rbac-learn get serviceaccount ci >/dev/null 2>&1 || { echo "❌ ServiceAccount 'ci' not found in rbac-learn"; exit 1; }
B=$(kubectl -n rbac-learn get rolebinding ci-pr -o json 2>/dev/null); [ -z "$B" ] && { echo "❌ RoleBinding 'ci-pr' not found in rbac-learn"; exit 1; }; export B
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
b=json.loads(os.environ['B'])
ref=b.get("roleRef") or {}
if ref.get("kind")!="Role" or ref.get("name")!="pod-reader":
    fail("RoleBinding ci-pr must reference Role pod-reader (got %r)"%ref)
subs={(s.get("kind"),s.get("name"),s.get("namespace")) for s in (b.get("subjects") or [])}
if ("ServiceAccount","ci","rbac-learn") not in subs:
    fail("RoleBinding ci-pr must have subject ServiceAccount rbac-learn:ci (got %s)"%sorted(subs))
print("✅ ServiceAccount ci bound to pod-reader; the SA identity can list pods in rbac-learn")
PY
