#!/bin/bash
# Diagnose&fix: Ingress shop must reference the EXISTING Secret shop-tls in spec.tls
# covering host shop.example.com, with a rule routing shop.example.com to web:80.
NS=ingress-learn
kubectl -n "$NS" get secret shop-tls >/dev/null 2>&1 || { echo "❌ Secret 'shop-tls' not found — don't delete it; point the Ingress at it."; exit 1; }
J=$(kubectl -n "$NS" get ingress shop -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Ingress 'shop' not found in $NS (don't delete it — fix its spec.tls secretName)."; exit 1; }
export J

python3 - <<'PY'
import os,sys,json
def fail(m): print("❌ "+m); sys.exit(1)
spec=json.loads(os.environ['J']).get("spec",{})
# spec.tls must reference shop-tls covering shop.example.com
match=[e for e in (spec.get("tls") or []) if e.get("secretName")=="shop-tls"]
if not match:
    names=[e.get("secretName") for e in (spec.get("tls") or [])]
    fail("spec.tls secretName is %s, not 'shop-tls' — the real Secret is shop-tls. Patch secretName to shop-tls."%names)
hosts=set()
for e in match: hosts |= set(e.get("hosts") or [])
if "shop.example.com" not in hosts:
    fail("the shop-tls tls entry does not cover host shop.example.com (lists %s)."%sorted(hosts))
# rule host shop.example.com must route to web:80
ok=False
for r in (spec.get("rules") or []):
    if r.get("host")!="shop.example.com": continue
    for p in ((r.get("http") or {}).get("paths") or []):
        b=(p.get("backend") or {}).get("service") or {}
        if b.get("name")=="web" and (b.get("port") or {}).get("number")==80: ok=True
if not ok:
    fail("no rule for shop.example.com routing to service web:80.")
print("✅ Ingress shop: spec.tls references shop-tls for shop.example.com, rule routes to web:80")
PY
