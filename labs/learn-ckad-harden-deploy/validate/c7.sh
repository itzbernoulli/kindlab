#!/bin/bash
J=$(kubectl -n shop get deploy checkout -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Deployment 'checkout' not found in namespace shop"; exit 1; }
export J
python3 - <<'PY'
import os,json
d=json.loads(os.environ['J'])
sp=d["spec"]; ps=sp["template"]["spec"]; cs=ps.get("containers",[]) or [{}]; cont=cs[0]
csc=cont.get("securityContext") or {}; psc=ps.get("securityContext") or {}
ro=csc.get("readOnlyRootFilesystem"); drop=[x.upper() for x in ((csc.get("capabilities") or {}).get("drop") or [])]
rnr=csc.get("runAsNonRoot", psc.get("runAsNonRoot")); uid=csc.get("runAsUser", psc.get("runAsUser"))
errs=[]
if ro is not True: errs.append("readOnlyRootFilesystem!=true")
if "ALL" not in drop: errs.append("capabilities.drop must include ALL")
if rnr is not True: errs.append("runAsNonRoot!=true")
if uid!=1001: errs.append("runAsUser!=1001 (got %r)"%uid)
if errs: print("❌ securityContext: "+", ".join(errs)); raise SystemExit(1)
print("✅ readOnlyRootFilesystem + runAsNonRoot + UID 1001 + drop ALL caps")
PY
