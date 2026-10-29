#!/bin/bash
NS=cks-locked
kubectl get ns "$NS" >/dev/null 2>&1 || { echo "❌ namespace $NS not found"; exit 1; }
J=$(kubectl get ns "$NS" -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ cannot read namespace $NS"; exit 1; }; export J
python3 - <<'PY'
import os,json,sys
L=json.loads(os.environ['J']).get("metadata",{}).get("labels",{}) or {}
def fail(m): print("❌ "+m); sys.exit(1)
P="pod-security.kubernetes.io/"
checks=[("enforce","restricted"),("enforce-version","v1.30"),("audit","baseline"),("audit-version","v1.30")]
for k,want in checks:
    got=L.get(P+k)
    if got!=want: fail("label %s%s is %r, expected %r"%(P,k,got,want))
print("✅ cks-locked: enforce=restricted@v1.30 + audit=baseline@v1.30")
PY
