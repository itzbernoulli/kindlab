#!/bin/bash
J=$(kubectl -n svcnet-learn get svc web-hl -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Service 'web-hl' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
s=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if s.get("clusterIP")!="None": fail("web-hl must be headless (clusterIP: None), got %r"%s.get("clusterIP"))
if (s.get("selector") or {}).get("app")!="web": fail("selector must be app=web")
print("✅ web-hl headless (clusterIP: None), selector app=web")
PY
