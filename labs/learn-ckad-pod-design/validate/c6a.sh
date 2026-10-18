#!/bin/bash
J=$(kubectl -n pod-design get pod secure-pod -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'secure-pod' not found in pod-design"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
ps=json.loads(os.environ['J'])["spec"]; psc=ps.get("securityContext") or {}; c=ps["containers"][0]; csc=c.get("securityContext") or {}
def fail(m): print("❌ "+m); sys.exit(1)
if psc.get("fsGroup")!=2000: fail("pod securityContext.fsGroup must be 2000 (got %r)"%psc.get("fsGroup"))
if csc.get("runAsNonRoot", psc.get("runAsNonRoot")) is not True: fail("runAsNonRoot must be true")
if csc.get("runAsUser", psc.get("runAsUser"))!=1000: fail("container runAsUser must be 1000")
print("✅ pod fsGroup 2000 + runAsNonRoot; container runAsUser 1000")
PY
