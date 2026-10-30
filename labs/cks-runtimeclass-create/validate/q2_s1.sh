#!/bin/bash
J=$(kubectl get runtimeclass kata -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ RuntimeClass 'kata' not found. Create it (handler kata + scheduling.nodeSelector + overhead.podFixed)."; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
d=json.loads(os.environ['J'])
def fail(m): print("❌ "+m); sys.exit(1)
if d.get("handler")!="kata": fail("handler must be exactly 'kata' (got %r)"%d.get("handler"))
sel=((d.get("scheduling") or {}).get("nodeSelector") or {})
if sel.get("runtime")!="kata":
    fail("scheduling.nodeSelector must contain runtime=kata (got %r)"%sel)
pf=((d.get("overhead") or {}).get("podFixed") or {})
if pf.get("memory")!="64Mi": fail("overhead.podFixed.memory must be 64Mi (got %r)"%pf.get("memory"))
if pf.get("cpu")!="50m":    fail("overhead.podFixed.cpu must be 50m (got %r)"%pf.get("cpu"))
print("✅ RuntimeClass 'kata': handler kata + nodeSelector runtime=kata + overhead podFixed mem 64Mi / cpu 50m")
PY
