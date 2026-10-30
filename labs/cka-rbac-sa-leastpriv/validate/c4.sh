#!/bin/bash
# Step 4: RoleBinding dev-deploy (in rbac-learn) references ClusterRole deploy-admin.
# Positive: dev can create deployments in rbac-learn. Negative: NOT in default (scope).
A=$(kubectl auth can-i create deployments --as=dev -n rbac-learn 2>/dev/null)
[ "$A" = "yes" ] || { echo "❌ dev cannot create deployments in rbac-learn (can-i='${A:-no}'). Bind ClusterRole deploy-admin via RoleBinding dev-deploy."; exit 1; }
D=$(kubectl auth can-i create deployments --as=dev -n default 2>/dev/null)
[ "$D" = "no" ] || { echo "❌ dev can create deployments in default too (can-i='${D}') — must use a RoleBinding (namespace-scoped), not a ClusterRoleBinding."; exit 1; }

R=$(kubectl get clusterrole deploy-admin -o json 2>/dev/null); [ -z "$R" ] && { echo "❌ ClusterRole 'deploy-admin' not found"; exit 1; }; export R
B=$(kubectl -n rbac-learn get rolebinding dev-deploy -o json 2>/dev/null); [ -z "$B" ] && { echo "❌ RoleBinding 'dev-deploy' not found in rbac-learn"; exit 1; }; export B
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
r=json.loads(os.environ['R'])
ok=False
for rule in (r.get("rules") or []):
    groups=rule.get("apiGroups") or []
    res=set(rule.get("resources") or [])
    verbs=set(rule.get("verbs") or [])
    if "deployments" in res and ("apps" in groups or "*" in groups) and {"get","list","create","update","delete"}<=verbs:
        ok=True
if not ok: fail("ClusterRole deploy-admin must allow get,list,create,update,delete on deployments in apiGroup apps")
b=json.loads(os.environ['B'])
ref=b.get("roleRef") or {}
if ref.get("kind")!="ClusterRole" or ref.get("name")!="deploy-admin":
    fail("RoleBinding dev-deploy must reference kind=ClusterRole name=deploy-admin (got %r)"%ref)
subs={(s.get("kind"),s.get("name")) for s in (b.get("subjects") or [])}
if ("User","dev") not in subs: fail("RoleBinding dev-deploy must have subject User dev")
print("✅ RoleBinding dev-deploy reuses ClusterRole deploy-admin in rbac-learn only (not default)")
PY
