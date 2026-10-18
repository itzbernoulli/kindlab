#!/bin/bash
J=$(kubectl -n svcnet-learn get svc web-np -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Service 'web-np' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
s=json.loads(os.environ['J'])["spec"]; p=(s.get("ports") or [{}])[0]
def fail(m): print("❌ "+m); sys.exit(1)
if s.get("type")!="NodePort": fail("type must be NodePort (got %r)"%s.get("type"))
if p.get("port")!=80 or str(p.get("targetPort"))!="80": fail("port 80 -> targetPort 80")
if p.get("nodePort")!=30080: fail("nodePort must be 30080 (got %r)"%p.get("nodePort"))
if (s.get("selector") or {}).get("app")!="web": fail("selector must be app=web")
print("✅ web-np NodePort 80 -> 80, nodePort 30080, selector app=web")
PY
