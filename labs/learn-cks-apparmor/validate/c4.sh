#!/bin/bash
# Pod 'unconfined' container 'hello' must have appArmorProfile.type == Unconfined (explicit opt-out)
# and must NOT reference k8s-deny-write.
NS=cks-apparmor
J=$(kubectl -n "$NS" get pod unconfined -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ pod 'unconfined' not found in $NS. Create it on $W1 with appArmorProfile.type Unconfined."; exit 1; }
export J
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
p=json.loads(os.environ['J'])
c=next((x for x in p["spec"].get("containers",[]) if x.get("name")=="hello"),None)
if not c: fail("container 'hello' not found in pod 'unconfined'.")
aa=(c.get("securityContext") or {}).get("appArmorProfile") or {}
t=aa.get("type"); lp=aa.get("localhostProfile")
ann=(p["metadata"].get("annotations") or {}).get("container.apparmor.security.beta.kubernetes.io/hello")
if lp=="k8s-deny-write" or ann=="localhost/k8s-deny-write":
    fail("'unconfined' references k8s-deny-write — it must be Unconfined, distinct from 'confined'.")
if t!="Unconfined":
    fail("container 'hello' appArmorProfile.type is %r (expected 'Unconfined')."%t)
print("✅ 'unconfined' container hello → appArmorProfile.type Unconfined (not k8s-deny-write)"); sys.exit(0)
PY
