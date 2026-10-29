#!/bin/bash
J=$(kubectl -n cks-podsec get pod restricted-app -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'restricted-app' not found in cks-podsec"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
c=json.loads(os.environ['J'])["spec"]["containers"][0]; csc=c.get("securityContext") or {}
def fail(m): print("❌ "+m); sys.exit(1)
if csc.get("allowPrivilegeEscalation") is not False: fail("allowPrivilegeEscalation must be false (got %r)"%csc.get("allowPrivilegeEscalation"))
drop=[x.upper() for x in ((csc.get("capabilities") or {}).get("drop") or [])]
if "ALL" not in drop: fail("capabilities.drop must include ALL (got %r)"%((csc.get("capabilities") or {}).get("drop")))
print("✅ restricted-app: allowPrivilegeEscalation=false + drop ALL")
PY
