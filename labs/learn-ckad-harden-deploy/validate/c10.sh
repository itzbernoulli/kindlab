#!/bin/bash
J=$(kubectl -n shop get svc checkout -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Service 'checkout' not found in namespace shop"; exit 1; }
export J
python3 - <<'PY'
import os,json
s=json.loads(os.environ['J'])["spec"]
if s.get("type") not in (None,"ClusterIP"): print("❌ Service type must be ClusterIP (got %r)"%s.get("type")); raise SystemExit(1)
p=(s.get("ports") or [{}])[0]
if p.get("port")!=8080: print("❌ Service port must be 8080 (got %r)"%p.get("port")); raise SystemExit(1)
if str(p.get("targetPort"))!="80": print("❌ Service targetPort must be 80 (got %r)"%p.get("targetPort")); raise SystemExit(1)
if (s.get("selector") or {}).get("app")!="checkout": print("❌ Service selector must be app=checkout (got %r)"%s.get("selector")); raise SystemExit(1)
print("✅ Service checkout ClusterIP 8080 -> 80, selector app=checkout")
PY
