#!/bin/bash
J=$(kubectl get runtimeclass -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ could not list RuntimeClasses."; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
items=json.loads(os.environ['J']).get("items",[])
def fail(m): print("❌ "+m); sys.exit(1)
h={ i["metadata"]["name"]: i.get("handler") for i in items }
if "gvisor" not in h: fail("RuntimeClass 'gvisor' is missing (create it in step 1)")
if "kata"   not in h: fail("RuntimeClass 'kata' is missing (create it in step 2)")
if h["gvisor"]!="runsc": fail("'gvisor' handler must be runsc (got %r)"%h["gvisor"])
if h["kata"]  !="kata":  fail("'kata' handler must be kata (got %r)"%h["kata"])
print("✅ both RuntimeClasses coexist: gvisor(runsc) + kata(kata)")
PY
