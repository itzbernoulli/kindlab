#!/bin/bash
# Ingress shop: ingressClassName nginx; host shop.example.com, path / Prefix -> web:80.
J=$(kubectl -n ingress-learn get ingress shop -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Ingress 'shop' not found in ingress-learn"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
sp=json.loads(os.environ["J"])["spec"]
if sp.get("ingressClassName")!="nginx": fail("ingressClassName must be 'nginx' (got %r)"%sp.get("ingressClassName"))
rule=next((r for r in (sp.get("rules") or []) if r.get("host")=="shop.example.com"),None)
if not rule: fail("no rule for host shop.example.com")
paths=(rule.get("http") or {}).get("paths") or []
p=next((x for x in paths if x.get("path")=="/"),None)
if not p: fail("no path '/' under shop.example.com")
if p.get("pathType")!="Prefix": fail("path '/' pathType must be Prefix (got %r)"%p.get("pathType"))
b=(p.get("backend") or {}).get("service") or {}
if b.get("name")!="web" or (b.get("port") or {}).get("number")!=80: fail("path '/' must route to Service web:80 (got %r)"%b)
print("✅ Ingress shop: class nginx, shop.example.com / Prefix -> web:80")
PY
