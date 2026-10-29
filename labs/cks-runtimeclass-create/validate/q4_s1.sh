#!/bin/bash
JN=$(kubectl -n runtimeclass-learn get pod normal    -o json 2>/dev/null); [ -z "$JN" ] && { echo "❌ pod 'normal' not found in runtimeclass-learn."; exit 1; }
JS=$(kubectl -n runtimeclass-learn get pod sandboxed -o json 2>/dev/null); [ -z "$JS" ] && { echo "❌ pod 'sandboxed' not found — create it (step 3) before contrasting."; exit 1; }
export JN JS
python3 - <<'PY'
import os,json,sys
n=json.loads(os.environ['JN'])["spec"]
s=json.loads(os.environ['JS'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
rcn=n.get("runtimeClassName")
if rcn: fail("'normal' must have NO runtimeClassName (default runtime), got %r"%rcn)
if s.get("runtimeClassName")!="gvisor": fail("'sandboxed' must keep runtimeClassName=gvisor (got %r)"%s.get("runtimeClassName"))
print("✅ 'normal' uses the default runtime (empty runtimeClassName); 'sandboxed' uses gvisor — they differ")
PY
