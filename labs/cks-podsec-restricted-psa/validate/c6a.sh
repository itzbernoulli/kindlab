#!/bin/bash
J=$(kubectl -n cks-podsec get pod restricted-app -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'restricted-app' not found in cks-podsec"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
ps=json.loads(os.environ['J'])["spec"]; psc=ps.get("securityContext") or {}
c=ps["containers"][0]; csc=c.get("securityContext") or {}
def fail(m): print("❌ "+m); sys.exit(1)
if csc.get("runAsNonRoot", psc.get("runAsNonRoot")) is not True: fail("runAsNonRoot must be true")
if csc.get("runAsUser", psc.get("runAsUser"))!=1000: fail("container runAsUser must be 1000 (got %r)"%csc.get("runAsUser"))
prof=psc.get("seccompProfile") or csc.get("seccompProfile") or {}
if prof.get("type")!="RuntimeDefault": fail("seccompProfile.type must be RuntimeDefault (got %r)"%prof.get("type"))
print("✅ restricted-app: runAsNonRoot + runAsUser 1000 + seccomp RuntimeDefault")
PY
