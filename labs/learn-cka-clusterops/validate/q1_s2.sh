#!/bin/bash
POD="static-web-$W1"
J=$(kubectl -n default get pod "$POD" -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ mirror pod '$POD' not found in default. Static pods appear as <name>-<node>; give the kubelet ~15s."; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
p=json.loads(os.environ['J'])
def fail(m): print("❌ "+m); sys.exit(1)
phase=p.get("status",{}).get("phase")
if phase!="Running": fail("mirror pod phase=%r (expected Running). Give the kubelet ~15s after writing the manifest."%phase)
cs=p["spec"].get("containers",[])
if len(cs)!=1: fail("expected exactly one container (got %d)"%len(cs))
c=cs[0]
if c.get("image")!="busybox:1.36": fail("container image=%r, expected busybox:1.36"%c.get("image"))
cmd=c.get("command") or []
if cmd!=["sleep","3600"]: fail("container command=%r, expected [\"sleep\",\"3600\"]"%cmd)
print("✅ mirror pod static-web Running with image busybox:1.36 and command sleep 3600")
PY
