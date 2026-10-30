#!/bin/bash
J=$(kubectl -n pod-design get pod secure-pod -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'secure-pod' not found in pod-design"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
ps=json.loads(os.environ['J'])["spec"]; c=ps["containers"][0]; csc=c.get("securityContext") or {}
def fail(m): print("❌ "+m); sys.exit(1)
if csc.get("readOnlyRootFilesystem") is not True: fail("readOnlyRootFilesystem must be true")
if csc.get("allowPrivilegeEscalation") is not False: fail("allowPrivilegeEscalation must be false")
caps=csc.get("capabilities") or {}; drop=[x.upper() for x in (caps.get("drop") or [])]; add=[x.upper() for x in (caps.get("add") or [])]
if "ALL" not in drop: fail("capabilities.drop must include ALL")
if "NET_BIND_SERVICE" not in add: fail("capabilities.add must include NET_BIND_SERVICE")
m=next((x for x in (c.get("volumeMounts") or []) if x.get("mountPath")=="/tmp"), None)
if not m: fail("need a writable emptyDir mounted at /tmp (for the read-only root)")
v=next((x for x in (ps.get("volumes") or []) if x["name"]==m["name"]), None)
if not v or "emptyDir" not in v: fail("/tmp must be an emptyDir")
print("✅ readOnlyRootFilesystem + allowPrivilegeEscalation false + drop ALL/add NET_BIND_SERVICE + emptyDir /tmp")
PY
