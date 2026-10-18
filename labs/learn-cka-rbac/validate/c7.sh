#!/bin/bash
# Step 7: CSR learn-dev is Approved (and issued).
J=$(kubectl get csr learn-dev -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ CSR 'learn-dev' not found"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
c=json.loads(os.environ['J'])
conds=c.get("status",{}).get("conditions") or []
approved=any(x.get("type")=="Approved" and x.get("status")=="True" for x in conds)
denied=any(x.get("type")=="Denied" and x.get("status")=="True" for x in conds)
if denied: fail("CSR learn-dev is Denied — approve it: kubectl certificate approve learn-dev")
if not approved: fail("CSR learn-dev not approved yet. Run: kubectl certificate approve learn-dev")
print("✅ CSR learn-dev is Approved")
PY
