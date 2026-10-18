#!/bin/bash
J=$(kubectl -n storage-learn get pvc broken-pvc -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ PVC 'broken-pvc' not found in storage-learn (keep the same name)"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
d=json.loads(os.environ['J']); sp=d["spec"]; st=d.get("status",{})
def fail(m): print("❌ "+m); sys.exit(1)
sc=sp.get("storageClassName")
if sc=="nonexistent-class": fail("broken-pvc still references 'nonexistent-class' — point it at a real StorageClass")
ph=st.get("phase")
if ph!="Bound": fail("broken-pvc phase is %r, expected 'Bound' (fix the storageClassName and let a pod trigger binding)"%ph)
print("✅ broken-pvc is Bound (bad storageClassName diagnosed and fixed)")
PY
