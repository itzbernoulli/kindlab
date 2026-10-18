#!/bin/bash
# Pod 'netlocked' on $W1, container 'hello' must request Localhost profile k8s-deny-net
# (bare profile name, not localhost/... and not a file path).
NS=cks-apparmor
J=$(kubectl -n "$NS" get pod netlocked -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ pod 'netlocked' not found in $NS. Create it pinned to $W1."; exit 1; }
export J W1
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
p=json.loads(os.environ['J']); spec=p["spec"]; w1=os.environ['W1']
if spec.get("nodeName")!=w1: fail("pod 'netlocked' is on '%s' (expected %s)."%(spec.get("nodeName") or "none",w1))
c=next((x for x in spec.get("containers",[]) if x.get("name")=="hello"),None)
if not c: fail("container 'hello' not found in pod 'netlocked'.")
aa=(c.get("securityContext") or {}).get("appArmorProfile") or {}
t=aa.get("type"); lp=aa.get("localhostProfile")
ann=(p["metadata"].get("annotations") or {}).get("container.apparmor.security.beta.kubernetes.io/hello")
if t=="Localhost" and lp=="k8s-deny-net":
    print("✅ pod 'netlocked' on %s: container hello → Localhost profile k8s-deny-net"%w1); sys.exit(0)
if ann=="localhost/k8s-deny-net":
    print("✅ pod 'netlocked' on %s: container hello → k8s-deny-net (via beta annotation)"%w1); sys.exit(0)
if lp and lp.startswith("localhost/"):
    fail("localhostProfile is %r — it must be the BARE profile name 'k8s-deny-net' (no 'localhost/' prefix)."%lp)
fail("container 'hello' does not request Localhost/k8s-deny-net (type=%r, localhostProfile=%r, annotation=%r)."%(t,lp,ann))
PY
