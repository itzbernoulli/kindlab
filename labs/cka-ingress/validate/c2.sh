#!/bin/bash
# Ingress shop also has /api Prefix -> api:80 (and still / -> web:80).
J=$(kubectl -n ingress-learn get ingress shop -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Ingress 'shop' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
sp=json.loads(os.environ["J"])["spec"]
rule=next((r for r in (sp.get("rules") or []) if r.get("host")=="shop.example.com"),None)
if not rule: fail("no rule for host shop.example.com")
paths=(rule.get("http") or {}).get("paths") or []
def backend(path):
    p=next((x for x in paths if x.get("path")==path),None)
    return p, ((p or {}).get("backend") or {}).get("service") or {}
pw,bw=backend("/"); pa,ba=backend("/api")
if not pw or bw.get("name")!="web": fail("the '/' -> web:80 rule must remain (got %r)"%bw)
if not pa: fail("no path '/api' under shop.example.com")
if pa.get("pathType")!="Prefix": fail("'/api' pathType must be Prefix (got %r)"%pa.get("pathType"))
if ba.get("name")!="api" or (ba.get("port") or {}).get("number")!=80: fail("'/api' must route to Service api:80 (got %r)"%ba)
print("✅ Ingress shop: / -> web:80 and /api -> api:80")
PY
