#!/bin/bash
J=$(kubectl -n cks-podsec get pod broken-app -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'broken-app' not found in cks-podsec (recreate it with the fix)"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
p=json.loads(os.environ['J']); ps=p["spec"]; psc=ps.get("securityContext") or {}
c=ps["containers"][0]; csc=c.get("securityContext") or {}
def fail(m): print("❌ "+m); sys.exit(1)
if csc.get("runAsNonRoot", psc.get("runAsNonRoot")) is not True: fail("runAsNonRoot must still be true")
u=csc.get("runAsUser", psc.get("runAsUser"))
if not isinstance(u,int) or u==0: fail("needs a non-zero runAsUser (got %r) — that's the fix"%u)
ph=p.get("status",{}).get("phase")
if ph!="Running": fail("broken-app is not Running yet (phase=%r) — fix the securityContext so the non-root image can start"%ph)
print("✅ broken-app Running as non-root UID %d"%u)
PY
