#!/bin/bash
J=$(kubectl -n pod-design get pod init-pod -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'init-pod' not found in pod-design"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
ps=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
ic=[c["name"] for c in ps.get("initContainers",[])]
if ic[:2]!=["init-a","init-b"]: fail("initContainers must be ordered init-a then init-b (got %s)"%ic)
app=next((c for c in ps.get("containers",[]) if c["name"]=="app"), None)
if not app: fail("missing main container 'app'")
m=next((x for x in (app.get("volumeMounts") or []) if x.get("mountPath")=="/work"), None)
if not m: fail("'app' must mount the shared volume at /work")
v=next((x for x in (ps.get("volumes") or []) if x["name"]==m["name"]), None)
if not v or "emptyDir" not in v: fail("/work must be an emptyDir shared with the init containers")
print("✅ init-pod: init-a then init-b (ordered) + app sharing emptyDir at /work")
PY
