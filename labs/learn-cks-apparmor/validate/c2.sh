#!/bin/bash
# Pod 'confined' must be on $W1 and container 'hello' must request Localhost profile k8s-deny-write
# (typed appArmorProfile field OR the beta annotation).
NS=cks-apparmor
J=$(kubectl -n "$NS" get pod confined -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ pod 'confined' not found in $NS. Create it pinned to $W1."; exit 1; }
export J W1
python3 - <<'PY'
import os,json,sys
def fail(m): print("❌ "+m); sys.exit(1)
p=json.loads(os.environ['J']); spec=p["spec"]; w1=os.environ['W1']
node=spec.get("nodeName")
if node!=w1: fail("pod 'confined' is on '%s' (expected %s). Set spec.nodeName: %s."%(node or "none",w1,w1))
c=next((x for x in spec.get("containers",[]) if x.get("name")=="hello"),None)
if not c: fail("container 'hello' not found in pod 'confined'.")
aa=(c.get("securityContext") or {}).get("appArmorProfile") or {}
t=aa.get("type"); lp=aa.get("localhostProfile")
ann=(p["metadata"].get("annotations") or {}).get("container.apparmor.security.beta.kubernetes.io/hello")
if t=="Localhost" and lp=="k8s-deny-write":
    print("✅ pod 'confined' on %s: container hello → Localhost profile k8s-deny-write"%w1); sys.exit(0)
if ann=="localhost/k8s-deny-write":
    print("✅ pod 'confined' on %s: container hello → k8s-deny-write (via beta annotation)"%w1); sys.exit(0)
fail("container 'hello' does not request Localhost/k8s-deny-write (type=%r, localhostProfile=%r, annotation=%r)."%(t,lp,ann))
PY
