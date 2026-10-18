#!/bin/bash
# Step 5: canary-route — ONE match ANDs PathPrefix / with Exact header x-env=canary → hello-canary:80.
J=$(kubectl -n gw-learn get httproute canary-route -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ HTTPRoute 'canary-route' not found in gw-learn"; exit 1; }
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
    for m in (r.get("matches") or []):
        path=(m.get("path") or {})
        if path.get("type")!="PathPrefix" or path.get("value")!="/":
            continue
        hdrs=m.get("headers") or []
        h=next((x for x in hdrs if x.get("name")=="x-env"), None)
        if not h or h.get("value")!="canary": continue
        if (h.get("type") or "Exact")!="Exact": continue
        if any(b.get("name")=="hello-canary" and b.get("port")==80 for b in (r.get("backendRefs") or [])):
            ok=True
if not ok:
    fail("need ONE match ANDing PathPrefix / and Exact header x-env=canary, backend hello-canary:80 (separate matches are ORed, not ANDed)")
print("✅ canary-route: PathPrefix / AND header x-env=canary → hello-canary:80")
PY
