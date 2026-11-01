#!/bin/bash
# Deployment hog scheduled & ready after lowering its CPU request to <= 1 core.
NS=resources-learn
J=$(kubectl -n "$NS" get deploy hog -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Deployment 'hog' not found in $NS"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys,re
def fail(m): print("❌ "+m); sys.exit(1)
def cpu_cores(v):
    if v is None: return None
    v=str(v)
    return float(v[:-1])/1000.0 if v.endswith("m") else float(v)
d=json.loads(os.environ["J"])
c=d["spec"]["template"]["spec"]["containers"][0]
req=((c.get("resources") or {}).get("requests") or {})
cpu=cpu_cores(req.get("cpu"))
if cpu is None: fail("container has no CPU request")
if cpu>1.0: fail("CPU request is still %r (> 1 core) — lower it so a node can fit it"%req.get("cpu"))
if d.get("status",{}).get("readyReplicas",0)<1: fail("Deployment 'hog' still has no ready replica — after lowering the request give it a moment to schedule")
print("✅ hog scheduled & ready with CPU request %s (<= 1 core)"%req.get("cpu"))
PY
