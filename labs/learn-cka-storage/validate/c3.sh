#!/bin/bash
J=$(kubectl -n storage-learn get pvc pvc-data -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ PVC 'pvc-data' not found in storage-learn"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
d=json.loads(os.environ['J']); sp=d["spec"]; st=d.get("status",{})
def fail(m): print("❌ "+m); sys.exit(1)
vn=sp.get("volumeName")
if vn!="pv-data": fail("spec.volumeName is %r, expected 'pv-data' (bind it explicitly)"%vn)
ph=st.get("phase")
if ph!="Bound": fail("pvc-data phase is %r, expected 'Bound' (check class/accessMode/size match pv-data)"%ph)
print("✅ pvc-data is Bound to pv-data")
PY
