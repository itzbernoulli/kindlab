#!/bin/bash
J=$(kubectl -n cks-podsec get pod noesc-app -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'noesc-app' not found in cks-podsec"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
c=json.loads(os.environ['J'])["spec"]["containers"][0]; csc=c.get("securityContext") or {}
def fail(m): print("❌ "+m); sys.exit(1)
if csc.get("allowPrivilegeEscalation") is not False: fail("allowPrivilegeEscalation must be explicitly false (got %r)"%csc.get("allowPrivilegeEscalation"))
if csc.get("privileged") is not False: fail("privileged must be explicitly false (got %r)"%csc.get("privileged"))
print("✅ noesc-app: allowPrivilegeEscalation=false + privileged=false")
PY
