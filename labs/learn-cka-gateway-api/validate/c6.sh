#!/bin/bash
# Step 6: hdr-route — rule-level RequestHeaderModifier set x-gateway=kindlab + backend hello:80.
J=$(kubectl -n gw-learn get httproute hdr-route -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ HTTPRoute 'hdr-route' not found in gw-learn"; exit 1; }
export J
python3 - <<'PY'
import os,json,sys
spec=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if not any(x.get("name")=="web-gw" and x.get("sectionName")=="http" for x in (spec.get("parentRefs") or [])):
    fail("parentRefs must include web-gw with sectionName http")
rules=spec.get("rules") or []
ok=False
for r in rules:
    be=any(b.get("name")=="hello" and b.get("port")==80 for b in (r.get("backendRefs") or []))
    if not be: continue
    for f in (r.get("filters") or []):
        if f.get("type")!="RequestHeaderModifier": continue
        sets=((f.get("requestHeaderModifier") or {}).get("set")) or []
        if any(s.get("name","").lower()=="x-gateway" and s.get("value")=="kindlab" for s in sets):
            ok=True
if not ok:
    fail("need a rule (backend hello:80) with filters[].type=RequestHeaderModifier setting x-gateway=kindlab")
print("✅ hdr-route: RequestHeaderModifier set x-gateway=kindlab + backend hello:80")
PY
