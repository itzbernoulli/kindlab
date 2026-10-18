#!/bin/bash
J=$(kubectl -n pod-design get pod downward-pod -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'downward-pod' not found in pod-design"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
ps=json.loads(os.environ['J'])["spec"]; c=ps["containers"][0]
def fail(m): print("❌ "+m); sys.exit(1)
m=next((x for x in (c.get("volumeMounts") or []) if x.get("mountPath")=="/podinfo"), None)
if not m: fail("need a volume mounted at /podinfo")
v=next((x for x in (ps.get("volumes") or []) if x["name"]==m["name"]), None)
if not v or "downwardAPI" not in v: fail("/podinfo must be a downwardAPI volume")
items=(v["downwardAPI"].get("items") or [])
if not any((it.get("fieldRef") or {}).get("fieldPath")=="metadata.labels" for it in items): fail("downwardAPI volume must expose metadata.labels")
print("✅ downwardAPI volume at /podinfo exposes metadata.labels")
PY
