#!/bin/bash
# Pod 'rtdefault' must have POD-LEVEL appArmorProfile.type == RuntimeDefault.
NS=cks-apparmor
J=$(kubectl -n "$NS" get pod rtdefault -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ pod 'rtdefault' not found in $NS. Create it on $W1 with pod-level appArmorProfile RuntimeDefault."; exit 1; }
export J
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
p=json.loads(os.environ['J']); spec=p["spec"]
aa=(spec.get("securityContext") or {}).get("appArmorProfile") or {}
t=aa.get("type")
if t!="RuntimeDefault":
    fail("spec.securityContext.appArmorProfile.type is %r (expected 'RuntimeDefault'). It must be POD-level, not container-level."%t)
if aa.get("localhostProfile"):
    fail("RuntimeDefault must not set localhostProfile.")
print("✅ 'rtdefault' has pod-level appArmorProfile.type RuntimeDefault"); sys.exit(0)
PY
