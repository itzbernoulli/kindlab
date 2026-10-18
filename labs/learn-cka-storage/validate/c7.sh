#!/bin/bash
JP=$(kubectl -n storage-learn get pvc dyn-pvc -o json 2>/dev/null); [ -z "$JP" ] && { echo "❌ PVC 'dyn-pvc' not found in storage-learn"; exit 1; }
JD=$(kubectl -n storage-learn get pod dyn-app -o json 2>/dev/null); [ -z "$JD" ] && { echo "❌ pod 'dyn-app' not found in storage-learn"; exit 1; }
export JP JD
python3 - <<'PY'
import os,json,sys
pvc=json.loads(os.environ['JP']); pod=json.loads(os.environ['JD'])
def fail(m): print("❌ "+m); sys.exit(1)
# PVC must NOT explicitly carry a non-default class name set by hand to something else.
# It should be Bound (default class dynamically provisioned once the pod scheduled).
ph=pvc.get("status",{}).get("phase")
if ph!="Bound": fail("dyn-pvc phase is %r, expected 'Bound' — create the consuming pod dyn-app to trigger WaitForFirstConsumer binding"%ph)
req=((pvc["spec"].get("resources") or {}).get("requests") or {}).get("storage")
if req!="500Mi": fail("dyn-pvc request is %r, expected '500Mi'"%req)
# the pod must consume dyn-pvc and be Running
vol=next((v for v in (pod["spec"].get("volumes") or []) if (v.get("persistentVolumeClaim") or {}).get("claimName")=="dyn-pvc"), None)
if not vol: fail("dyn-app must use persistentVolumeClaim claimName 'dyn-pvc'")
pp=pod.get("status",{}).get("phase")
if pp!="Running": fail("dyn-app phase is %r, expected 'Running'"%pp)
print("✅ dyn-pvc Bound via default class + dyn-app Running")
PY
