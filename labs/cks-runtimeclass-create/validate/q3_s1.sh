#!/bin/bash
J=$(kubectl -n runtimeclass-learn get pod sandboxed -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'sandboxed' not found in runtimeclass-learn."; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
sp=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
rc=sp.get("runtimeClassName")
if rc!="gvisor": fail("spec.runtimeClassName must be 'gvisor' (got %r)"%rc)
imgs=[c.get("image") for c in sp.get("containers",[])]
if "busybox:1.36" not in imgs: fail("container image must be busybox:1.36 (got %r)"%imgs)
print("✅ pod 'sandboxed' requests runtimeClassName 'gvisor'")
PY
