#!/bin/bash
# Step 4: HTTPRoute web-route — parentRef web-gw/http + hostname + PathPrefix / → hello:80.
J=$(kubectl -n gw-learn get httproute web-route -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ HTTPRoute 'web-route' not found in gw-learn"; exit 1; }
export J
python3 - <<'PY'
import os,json,sys
spec=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
prs=spec.get("parentRefs") or []
p=next((x for x in prs if x.get("name")=="web-gw"), None)
if not p: fail("no parentRef to 'web-gw' (parentRefs: %s)"%[x.get("name") for x in prs])
if p.get("sectionName")!="http": fail("parentRef web-gw sectionName=%r, expected 'http'"%p.get("sectionName"))
if "hello.example.com" not in (spec.get("hostnames") or []):
    fail("hostnames must include 'hello.example.com' (got %s)"%spec.get("hostnames"))
rules=spec.get("rules") or []
ok=False
for r in rules:
    pm=any((m.get("path") or {}).get("type")=="PathPrefix" and (m.get("path") or {}).get("value")=="/" for m in (r.get("matches") or []))
    be=any(b.get("name")=="hello" and b.get("port")==80 for b in (r.get("backendRefs") or []))
    if pm and be: ok=True
if not ok: fail("need a rule with PathPrefix '/' match AND backendRef hello:80")
print("✅ web-route: parentRef web-gw/http + hostname + PathPrefix / → hello:80")
PY
