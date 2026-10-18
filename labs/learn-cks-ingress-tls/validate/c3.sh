#!/bin/bash
# Ingress web rule for demo.example.com: path / Prefix -> service web:80
NS=ingress-learn
J=$(kubectl -n "$NS" get ingress web -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Ingress 'web' not found in $NS."; exit 1; }
export J

python3 - <<'PY'
import os,sys,json
def fail(m): print("❌ "+m); sys.exit(1)
spec=json.loads(os.environ['J']).get("spec",{})
rules=[r for r in (spec.get("rules") or []) if r.get("host")=="demo.example.com"]
if not rules: fail("no rule with host demo.example.com. Add a rule routing that host.")
ok=False
seen=[]
for r in rules:
    for p in ((r.get("http") or {}).get("paths") or []):
        b=(p.get("backend") or {}).get("service") or {}
        port=(b.get("port") or {}).get("number")
        seen.append("path=%s type=%s svc=%s:%s"%(p.get("path"),p.get("pathType"),b.get("name"),port))
        if p.get("path")=="/" and p.get("pathType")=="Prefix" and b.get("name")=="web" and port==80:
            ok=True
if not ok:
    fail("rule demo.example.com has no path '/' (Prefix) -> web:80. Found: %s"%("; ".join(seen) or "no paths"))
print("✅ Ingress rule host demo.example.com: path / Prefix routes to service web:80")
PY
