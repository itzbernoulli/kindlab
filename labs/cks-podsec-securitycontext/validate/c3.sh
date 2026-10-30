#!/bin/bash
J=$(kubectl -n cks-podsec get pod ro-app -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'ro-app' not found in cks-podsec"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
ps=json.loads(os.environ['J'])["spec"]; c=ps["containers"][0]; csc=c.get("securityContext") or {}
def fail(m): print("❌ "+m); sys.exit(1)
if csc.get("readOnlyRootFilesystem") is not True: fail("container readOnlyRootFilesystem must be true")
m=next((x for x in (c.get("volumeMounts") or []) if x.get("mountPath")=="/tmp"), None)
if not m: fail("need a writable volume mounted at /tmp")
v=next((x for x in (ps.get("volumes") or []) if x.get("name")==m.get("name")), None)
if not v or "emptyDir" not in v: fail("the /tmp volume must be an emptyDir")
print("✅ ro-app: readOnlyRootFilesystem + emptyDir at /tmp")
PY
