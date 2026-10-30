#!/bin/bash
# Step 7: split-route — ONE rule, two backendRefs: hello:80 weight 90 + hello-canary:80 weight 10.
J=$(kubectl -n gw-learn get httproute split-route -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ HTTPRoute 'split-route' not found in gw-learn"; exit 1; }
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
    bes={b.get("name"):b for b in (r.get("backendRefs") or [])}
    h=bes.get("hello"); c=bes.get("hello-canary")
    if not h or not c: continue
    if h.get("port")!=80 or c.get("port")!=80: continue
    if h.get("weight")==90 and c.get("weight")==10:
        ok=True
if not ok:
    fail("need ONE rule with backendRefs hello:80 weight 90 AND hello-canary:80 weight 10")
print("✅ split-route: hello:80 weight 90 + hello-canary:80 weight 10 in one rule")
PY
