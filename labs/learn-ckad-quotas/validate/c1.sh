#!/bin/bash
J=$(kubectl -n ckad-quotas get resourcequota compute-quota -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ ResourceQuota 'compute-quota' not found in ckad-quotas"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
h=(json.loads(os.environ['J']).get("spec") or {}).get("hard") or {}
def fail(m): print("❌ "+m); sys.exit(1)
want={"requests.cpu":"1","requests.memory":"1Gi","limits.cpu":"2","limits.memory":"2Gi"}
for k,v in want.items():
    if h.get(k)!=v: fail("compute-quota hard %s=%r, want %r (all four: requests 1/1Gi, limits 2/2Gi)"%(k,h.get(k),v))
print("✅ compute-quota: requests 1/1Gi, limits 2/2Gi")
PY
