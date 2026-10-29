#!/bin/bash
J=$(kubectl -n cks-podsec get pod cap-app -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'cap-app' not found in cks-podsec"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
c=json.loads(os.environ['J'])["spec"]["containers"][0]; csc=c.get("securityContext") or {}
def fail(m): print("❌ "+m); sys.exit(1)
caps=csc.get("capabilities") or {}
drop=[x.upper() for x in (caps.get("drop") or [])]
add=[x.upper() for x in (caps.get("add") or [])]
if drop!=["ALL"]: fail("capabilities.drop must be exactly [ALL] (got %r)"%(caps.get("drop")))
if add!=["NET_BIND_SERVICE"]: fail("capabilities.add must be exactly [NET_BIND_SERVICE] — drop the CAP_ prefix and add nothing else (got %r)"%(caps.get("add")))
print("✅ cap-app drops ALL and adds only NET_BIND_SERVICE")
PY
