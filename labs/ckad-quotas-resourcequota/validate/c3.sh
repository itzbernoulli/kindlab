#!/bin/bash
J=$(kubectl -n ckad-quotas get resourcequota object-quota -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ ResourceQuota 'object-quota' not found in ckad-quotas"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
h=(json.loads(os.environ['J']).get("spec") or {}).get("hard") or {}
def fail(m): print("❌ "+m); sys.exit(1)
if h.get("configmaps")!="3": fail("object-quota hard.configmaps=%r, want '3'"%h.get("configmaps"))
if h.get("count/deployments.apps")!="2": fail("object-quota hard['count/deployments.apps']=%r, want '2'"%h.get("count/deployments.apps"))
print("✅ object-quota: configmaps=3 and count/deployments.apps=2")
PY
