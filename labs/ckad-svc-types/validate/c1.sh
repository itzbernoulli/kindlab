#!/bin/bash
J=$(kubectl -n svcnet-learn get svc web-svc -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Service 'web-svc' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
s=json.loads(os.environ['J'])["spec"]; p=(s.get("ports") or [{}])[0]
def fail(m): print("❌ "+m); sys.exit(1)
if s.get("type") not in (None,"ClusterIP"): fail("web-svc type must be ClusterIP (got %r)"%s.get("type"))
if p.get("port")!=80: fail("port must be 80")
if str(p.get("targetPort"))!="http": fail("targetPort must be the named port 'http' (got %r)"%p.get("targetPort"))
if (s.get("selector") or {}).get("app")!="web": fail("selector must be app=web")
print("✅ web-svc ClusterIP port 80 -> targetPort 'http', selector app=web")
PY
