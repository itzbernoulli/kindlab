#!/bin/bash
J=$(kubectl -n cks-podsec get pod seccomp-app -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'seccomp-app' not found in cks-podsec"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
ps=json.loads(os.environ['J'])["spec"]; psc=ps.get("securityContext") or {}
def fail(m): print("❌ "+m); sys.exit(1)
sp=(psc.get("seccompProfile") or {}).get("type")
if sp!="RuntimeDefault": fail("spec.securityContext.seccompProfile.type must be RuntimeDefault (case-sensitive; got %r)"%sp)
print("✅ seccomp-app: pod seccompProfile.type=RuntimeDefault")
PY
