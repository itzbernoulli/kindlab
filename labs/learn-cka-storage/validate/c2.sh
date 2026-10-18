#!/bin/bash
J=$(kubectl get pv pv-data -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ PersistentVolume 'pv-data' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
sp=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
cap=(sp.get("capacity") or {}).get("storage")
if cap!="1Gi": fail("capacity.storage is %r, expected '1Gi'"%cap)
am=sp.get("accessModes") or []
if am!=["ReadWriteOnce"]: fail("accessModes is %r, expected ['ReadWriteOnce']"%am)
sc=sp.get("storageClassName")
if sc!="fast-local": fail("storageClassName is %r, expected 'fast-local'"%sc)
rp=sp.get("persistentVolumeReclaimPolicy")
if rp!="Retain": fail("persistentVolumeReclaimPolicy is %r, expected 'Retain'"%rp)
hp=(sp.get("hostPath") or {}).get("path")
if hp!="/mnt/data": fail("hostPath.path is %r, expected '/mnt/data'"%hp)
print("✅ pv-data: 1Gi RWO, class fast-local, hostPath /mnt/data, reclaimPolicy Retain")
PY
