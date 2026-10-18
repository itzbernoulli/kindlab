#!/bin/bash
# Step 2: ClusterRole node-reader (get,list nodes) + ClusterRoleBinding to dev.
# Positive: dev can list nodes cluster-wide. Negative: dev cannot list secrets anywhere.
CAN=$(kubectl auth can-i list nodes --as=dev 2>/dev/null)
[ "$CAN" = "yes" ] || { echo "❌ dev cannot list nodes (can-i='${CAN:-no}'). Create ClusterRole node-reader + ClusterRoleBinding dev-nr to dev."; exit 1; }
SEC=$(kubectl auth can-i list secrets --as=dev -A 2>/dev/null)
[ "$SEC" = "no" ] || { echo "❌ dev can also list secrets (can-i='${SEC}') — node-reader must allow only get,list on nodes."; exit 1; }

J=$(kubectl get clusterrole node-reader -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ ClusterRole 'node-reader' not found"; exit 1; }; export J
B=$(kubectl get clusterrolebinding dev-nr -o json 2>/dev/null); [ -z "$B" ] && { echo "❌ ClusterRoleBinding 'dev-nr' not found"; exit 1; }; export B
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
r=json.loads(os.environ['J'])
ok=False
for rule in (r.get("rules") or []):
    groups=rule.get("apiGroups") or []
    res=set(rule.get("resources") or [])
    verbs=set(rule.get("verbs") or [])
    if "nodes" in res and ("" in groups or "*" in groups) and {"get","list"}<=verbs:
        ok=True
if not ok: fail("ClusterRole node-reader must allow get,list on nodes")
b=json.loads(os.environ['B'])
ref=b.get("roleRef") or {}
if ref.get("kind")!="ClusterRole" or ref.get("name")!="node-reader":
    fail("ClusterRoleBinding dev-nr must reference ClusterRole node-reader (got %r)"%ref)
subs={(s.get("kind"),s.get("name")) for s in (b.get("subjects") or [])}
if ("User","dev") not in subs: fail("ClusterRoleBinding dev-nr must have subject User dev (got %s)"%sorted(subs))
print("✅ ClusterRole node-reader bound cluster-wide to dev; can list nodes but not secrets")
PY
