#!/bin/bash
J=$(kubectl -n cks-podsec get pod secure-app -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'secure-app' not found in cks-podsec"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
p=json.loads(os.environ['J']); ps=p["spec"]; psc=ps.get("securityContext") or {}
c=ps["containers"][0]; csc=c.get("securityContext") or {}
def fail(m): print("❌ "+m); sys.exit(1)
if c.get("image")!="busybox:1.36": fail("container image must be busybox:1.36 (got %r)"%c.get("image"))
if csc.get("runAsNonRoot", psc.get("runAsNonRoot")) is not True: fail("runAsNonRoot must be true")
if csc.get("runAsUser", psc.get("runAsUser"))!=1000: fail("runAsUser must be 1000 (got %r)"%csc.get("runAsUser"))
if p.get("status",{}).get("phase")!="Running": fail("pod is not Running yet (phase=%r)"%p.get("status",{}).get("phase"))
print("✅ secure-app runs non-root as UID 1000")
PY
