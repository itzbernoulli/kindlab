#!/bin/bash
LJ=$(kubectl -n ckad-quotas get limitrange defaults -o json 2>/dev/null); [ -z "$LJ" ] && { echo "❌ LimitRange 'defaults' not found in ckad-quotas"; exit 1; }; export LJ
J=$(kubectl -n ckad-quotas get pod nodefaults -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'nodefaults' not found (create the LimitRange, then the bare pod)"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
lr=json.loads(os.environ['LJ'])["spec"]["limits"]
c=next((x for x in lr if x.get("type")=="Container"),None)
if not c: fail("LimitRange 'defaults' needs a type: Container entry")
dr=c.get("defaultRequest") or {}; df=c.get("default") or {}
for name,got,exp in [("defaultRequest.cpu",dr.get("cpu"),"200m"),("defaultRequest.memory",dr.get("memory"),"128Mi"),
                     ("default.cpu",df.get("cpu"),"500m"),("default.memory",df.get("memory"),"256Mi")]:
    if got!=exp: fail("LimitRange %s=%r, want %r"%(name,got,exp))
r=json.loads(os.environ['J'])["spec"]["containers"][0].get("resources") or {}
req=r.get("requests") or {}; lim=r.get("limits") or {}
for name,got,exp in [("pod requests.cpu",req.get("cpu"),"200m"),("pod requests.memory",req.get("memory"),"128Mi"),
                     ("pod limits.cpu",lim.get("cpu"),"500m"),("pod limits.memory",lim.get("memory"),"256Mi")]:
    if got!=exp: fail("%s=%r, want %r (pod didn't inherit the LimitRange defaults — create the LimitRange BEFORE the pod)"%(name,got,exp))
print("✅ nodefaults inherited requests 200m/128Mi + limits 500m/256Mi from LimitRange 'defaults'")
PY
