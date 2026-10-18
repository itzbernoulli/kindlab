#!/bin/bash
J=$(kubectl get crd sprockets.demo.example.com -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ CRD sprockets.demo.example.com is missing — re-run setup, then patch its v1 to served:true (don't recreate)"; exit 1; }
export J
python3 - <<'PY'
import os,json,sys
c=json.loads(os.environ['J'])
def fail(m): print("❌ "+m); sys.exit(1)
v=next((x for x in (c["spec"].get("versions") or []) if x.get("name")=="v1"), None)
if not v: fail("CRD has no v1 version")
if not v.get("served"): fail("v1 is still served:false — patch spec.versions[0].served to true so the Sprocket endpoint is exposed")
if not v.get("storage"): fail("v1 must remain storage:true")
PY
rc=$?; [ $rc -ne 0 ] && exit $rc
S=$(kubectl -n crd-learn get sprocket sp1 -o json 2>/dev/null)
[ -z "$S" ] && { echo "❌ Sprocket 'sp1' not found in crd-learn — after fixing served:true, create it with spec.teeth=12"; exit 1; }
export S
python3 - <<'PY'
import os,json,sys
s=json.loads(os.environ['S'])
def fail(m): print("❌ "+m); sys.exit(1)
if s.get("apiVersion")!="demo.example.com/v1": fail("Sprocket apiVersion must be demo.example.com/v1 (got %r)"%s.get("apiVersion"))
if (s.get("spec") or {}).get("teeth")!=12: fail("spec.teeth must be 12 (got %r)"%(s.get("spec") or {}).get("teeth"))
print("✅ sprockets CRD v1 now served; Sprocket 'sp1' in crd-learn with teeth=12")
PY
