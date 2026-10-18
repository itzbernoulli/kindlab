#!/bin/bash
J=$(kubectl -n svcnet-learn get svc web-sa -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ Service 'web-sa' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
s=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if s.get("sessionAffinity")!="ClientIP": fail("sessionAffinity must be ClientIP")
t=((s.get("sessionAffinityConfig") or {}).get("clientIP") or {}).get("timeoutSeconds")
if t!=3600: fail("sessionAffinityConfig.clientIP.timeoutSeconds must be 3600 (got %r)"%t)
print("✅ web-sa sessionAffinity ClientIP, timeout 3600")
PY
