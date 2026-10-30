#!/bin/bash
J=$(kubectl -n storage-learn get pod app -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'app' not found in storage-learn"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
d=json.loads(os.environ['J']); sp=d["spec"]; st=d.get("status",{})
def fail(m): print("❌ "+m); sys.exit(1)
vol=next((v for v in (sp.get("volumes") or []) if (v.get("persistentVolumeClaim") or {}).get("claimName")=="pvc-data"), None)
if not vol: fail("pod app must have a volume using persistentVolumeClaim claimName 'pvc-data'")
c=sp["containers"][0]
m=next((x for x in (c.get("volumeMounts") or []) if x.get("mountPath")=="/data"), None)
if not m: fail("container must mount a volume at /data")
if m.get("name")!=vol["name"]: fail("the /data mount must reference the pvc-data volume (names differ)")
ph=st.get("phase")
if ph!="Running": fail("pod app phase is %r, expected 'Running' (use 'sleep 3600' and a Bound PVC)"%ph)
print("✅ pod app is Running with pvc-data mounted at /data")
PY
