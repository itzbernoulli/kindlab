#!/bin/bash
# Step 5: least privilege via resourceNames — dev can get app-config, NOT other-config.
A=$(kubectl auth can-i get configmaps/app-config   --as=dev -n rbac-learn 2>/dev/null)
B=$(kubectl auth can-i get configmaps/other-config --as=dev -n rbac-learn 2>/dev/null)
if [ "$A" != "yes" ]; then echo "❌ dev cannot get app-config (can-i='${A:-no}'). Create Role cm-reader with resourceNames=app-config + bind to dev."; exit 1; fi
if [ "$B" != "no" ]; then echo "❌ dev can also get other-config (can-i='${B}') — too broad. Restrict with resourceNames: [app-config]."; exit 1; fi

J=$(kubectl -n rbac-learn get role cm-reader -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Role 'cm-reader' not found in rbac-learn"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
r=json.loads(os.environ['J'])
ok=False
for rule in (r.get("rules") or []):
    res=set(rule.get("resources") or [])
    verbs=set(rule.get("verbs") or [])
    names=set(rule.get("resourceNames") or [])
    if "configmaps" in res and "get" in verbs and names=={"app-config"}:
        ok=True
if not ok: fail("Role cm-reader must have a rule: get configmaps with resourceNames exactly [app-config]")
print("✅ Role cm-reader restricted via resourceNames; dev can get app-config but not other-config")
PY
