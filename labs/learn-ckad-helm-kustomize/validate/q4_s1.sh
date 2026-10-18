#!/bin/bash
# Step 4: release 'demo' is deployed AND on revision 3.
# The deployed-state release Secret is labelled owner=helm,status=deployed,name=demo,version=<rev>.
J=$(kubectl get secret -n helm-learn -l owner=helm,status=deployed,name=demo -o json 2>/dev/null); export J
python3 - <<'PY'
import os,json,sys
items=json.loads(os.environ.get('J') or '{}').get("items",[])
def fail(m): print("❌ "+m); sys.exit(1)
if not items: fail("no deployed-state release Secret for 'demo' in helm-learn — confirm with: helm list -n helm-learn (STATUS should be deployed)")
labels=items[0].get("metadata",{}).get("labels",{})
st=labels.get("status")
ver=labels.get("version")
if st!="deployed": fail("release 'demo' status is %r, expected 'deployed'"%st)
if ver!="3": fail("release 'demo' is on revision %r, expected 3 — you need exactly three operations: install + two upgrades (steps 1,2,3)"%ver)
print("✅ release 'demo' is deployed and on revision 3 in helm-learn")
PY
