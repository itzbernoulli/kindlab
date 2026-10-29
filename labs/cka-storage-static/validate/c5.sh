#!/bin/bash
J=$(kubectl -n storage-learn get pod sub-app -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'sub-app' not found in storage-learn"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
sp=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
vol=next((v for v in (sp.get("volumes") or []) if (v.get("persistentVolumeClaim") or {}).get("claimName")=="pvc-data"), None)
if not vol: fail("sub-app must have a volume using persistentVolumeClaim claimName 'pvc-data'")
c=sp["containers"][0]
m=next((x for x in (c.get("volumeMounts") or []) if x.get("mountPath")=="/var/log/app"), None)
if not m: fail("container must mount a volume at /var/log/app")
if m.get("name")!=vol["name"]: fail("the /var/log/app mount must reference the pvc-data volume (names differ)")
if m.get("subPath")!="logs": fail("volumeMount at /var/log/app must set subPath 'logs' (got %r)"%m.get("subPath"))
print("✅ sub-app mounts pvc-data at /var/log/app with subPath logs")
PY
