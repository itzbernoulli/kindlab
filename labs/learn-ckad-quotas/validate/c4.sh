#!/bin/bash
J=$(kubectl -n ckad-quotas get resourcequota be-quota -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ ResourceQuota 'be-quota' not found in ckad-quotas"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
sp=json.loads(os.environ['J']).get("spec") or {}
h=sp.get("hard") or {}; scopes=sp.get("scopes") or []
def fail(m): print("❌ "+m); sys.exit(1)
if h.get("pods")!="1": fail("be-quota hard.pods=%r, want '1'"%h.get("pods"))
if "BestEffort" not in scopes: fail("be-quota scopes=%r, must contain 'BestEffort'"%scopes)
print("✅ be-quota: pods=1 scoped to BestEffort")
PY
