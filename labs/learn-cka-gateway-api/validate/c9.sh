#!/bin/bash
# Step 9 diagnose & fix: broken-route must now parentRef web-gw/http and backend hello:80.
if ! kubectl -n gw-learn get httproute broken-route >/dev/null 2>&1; then
  echo "❌ HTTPRoute 'broken-route' not found (don't delete it — fix its refs in place)"; exit 1
fi
J=$(kubectl -n gw-learn get httproute broken-route -o json 2>/dev/null); export J
python3 - <<'PY'
import os,json,sys
spec=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
p=next((x for x in (spec.get("parentRefs") or []) if x.get("name")=="web-gw"), None)
if not p: fail("parentRefs still doesn't point at 'web-gw' — fix it to the real Gateway")
if p.get("sectionName")!="http": fail("parentRef web-gw sectionName=%r, expected 'http'"%p.get("sectionName"))
be=[b for r in (spec.get("rules") or []) for b in (r.get("backendRefs") or [])]
if not any(b.get("name")=="hello" and b.get("port")==80 for b in be):
    fail("backendRef still doesn't point at Service hello:80 — fix it to the real Service")
print("✅ broken-route fixed: parentRef web-gw/http + backend hello:80")
PY
