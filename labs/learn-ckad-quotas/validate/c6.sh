#!/bin/bash
J=$(kubectl -n ckad-quotas get limitrange constraints -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ LimitRange 'constraints' not found in ckad-quotas"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
lr=json.loads(os.environ['J'])["spec"]["limits"]
c=next((x for x in lr if x.get("type")=="Container"),None)
if not c: fail("LimitRange 'constraints' needs a type: Container entry")
mn=c.get("min") or {}; mx=c.get("max") or {}
for name,got,exp in [("min.cpu",mn.get("cpu"),"100m"),("min.memory",mn.get("memory"),"64Mi"),
                     ("max.cpu",mx.get("cpu"),"1"),("max.memory",mx.get("memory"),"1Gi")]:
    if got!=exp: fail("constraints %s=%r, want %r"%(name,got,exp))
print("✅ constraints: min cpu 100m/mem 64Mi, max cpu 1/mem 1Gi")
PY
