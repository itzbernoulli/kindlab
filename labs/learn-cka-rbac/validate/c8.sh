#!/bin/bash
# Step 8 (diagnose & fix): auditor can list secrets in rbac-learn.
# The seeded RoleBinding auditor-sr had a dangling roleRef; learner repoints it
# to the existing Role secret-reader (rules unchanged).
CAN=$(kubectl auth can-i list secrets --as=auditor -n rbac-learn 2>/dev/null)
[ "$CAN" = "yes" ] || { echo "❌ auditor still cannot list secrets (can-i='${CAN:-no}'). The RoleBinding auditor-sr has a dangling roleRef — repoint it to Role secret-reader (delete+recreate, roleRef is immutable)."; exit 1; }

B=$(kubectl -n rbac-learn get rolebinding auditor-sr -o json 2>/dev/null); [ -z "$B" ] && { echo "❌ RoleBinding 'auditor-sr' not found in rbac-learn"; exit 1; }; export B
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
b=json.loads(os.environ['B'])
ref=b.get("roleRef") or {}
if ref.get("kind")!="Role" or ref.get("name")!="secret-reader":
    fail("RoleBinding auditor-sr must reference Role secret-reader (got %r)"%ref)
subs={(s.get("kind"),s.get("name")) for s in (b.get("subjects") or [])}
if ("User","auditor") not in subs: fail("RoleBinding auditor-sr must have subject User auditor")
print("✅ auditor can list secrets in rbac-learn (dangling roleRef fixed)")
PY
