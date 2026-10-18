#!/bin/bash
# Step 8: Ingress web-ing — host hello.example.com, path / Prefix → hello:80.
J=$(kubectl -n gw-learn get ingress web-ing -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Ingress 'web-ing' not found in gw-learn — create it routing hello.example.com/ to hello:80"; exit 1; }
export J
python3 - <<'PY'
import os,json,sys
spec=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
ok=False
for r in spec.get("rules") or []:
    if r.get("host")!="hello.example.com": continue
    for p in ((r.get("http") or {}).get("paths") or []):
        if p.get("path")!="/": continue
        if p.get("pathType")!="Prefix": continue
        svc=(p.get("backend") or {}).get("service") or {}
        port=(svc.get("port") or {})
        if svc.get("name")=="hello" and port.get("number")==80:
            ok=True
if not ok:
    fail("need rule host hello.example.com, path '/' pathType Prefix, backend service hello port 80")
print("✅ Ingress web-ing: host hello.example.com, path / Prefix → hello:80")
PY
