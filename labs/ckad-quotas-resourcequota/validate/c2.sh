#!/bin/bash
J=$(kubectl -n ckad-quotas get pod fits -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'fits' not found in ckad-quotas (the compute quota rejects pods with no resources)"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
d=json.loads(os.environ['J'])
def fail(m): print("❌ "+m); sys.exit(1)
ph=d.get("status",{}).get("phase")
if ph!="Running": fail("pod 'fits' phase is %r, want Running"%ph)
cs=d["spec"]["containers"]
if len(cs)!=1 or cs[0].get("name")!="app": fail("need exactly one container named 'app'")
r=cs[0].get("resources") or {}
req=r.get("requests") or {}; lim=r.get("limits") or {}
want=[("requests.cpu",req.get("cpu"),"200m"),("requests.memory",req.get("memory"),"256Mi"),
      ("limits.cpu",lim.get("cpu"),"500m"),("limits.memory",lim.get("memory"),"512Mi")]
for name,got,exp in want:
    if got!=exp: fail("%s=%r, want %r"%(name,got,exp))
print("✅ fits: Running with requests 200m/256Mi + limits 500m/512Mi")
PY
