#!/bin/bash
J=$(kubectl get runtimeclass gvisor -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ RuntimeClass 'gvisor' not found. Create it (apiVersion node.k8s.io/v1, top-level handler: runsc)."; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
d=json.loads(os.environ['J'])
def fail(m): print("❌ "+m); sys.exit(1)
if d.get("kind")!="RuntimeClass": fail("object 'gvisor' is not a RuntimeClass (kind=%r)"%d.get("kind"))
h=d.get("handler")
if h!="runsc": fail("handler must be exactly 'runsc' (got %r). It is a TOP-LEVEL field, not under spec."%h)
print("✅ RuntimeClass 'gvisor' exists with handler 'runsc'")
PY
