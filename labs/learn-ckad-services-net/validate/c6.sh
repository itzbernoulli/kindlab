#!/bin/bash
J=$(kubectl -n svcnet-learn get ingress web-ing -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Ingress 'web-ing' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
s=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if s.get("ingressClassName")!="nginx": fail("ingressClassName must be nginx")
tls=s.get("tls") or []
if not any(t.get("secretName")=="web-tls" for t in tls): fail("tls must reference secret web-tls")
rules=s.get("rules") or []
ok=False
for r in rules:
    for p in ((r.get("http") or {}).get("paths") or []):
        b=(p.get("backend") or {}).get("service") or {}
        if p.get("pathType")=="Prefix" and p.get("path")=="/" and b.get("name")=="web-svc" and (b.get("port") or {}).get("number")==80: ok=True
if not ok: fail("need a Prefix path '/' to backend service web-svc:80")
print("✅ web-ing: class nginx, Prefix / -> web-svc:80, TLS web-tls")
PY
