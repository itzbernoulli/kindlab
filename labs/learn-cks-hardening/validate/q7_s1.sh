#!/bin/bash
NS=cks-learn
# 1) SA no-token must have automountServiceAccountToken: false
AM=$(kubectl -n "$NS" get serviceaccount no-token -o jsonpath='{.automountServiceAccountToken}' 2>/dev/null)
if [ -z "$AM" ]; then
  echo "❌ ServiceAccount 'no-token' not found (or automount field unset) in $NS. Create it with automountServiceAccountToken: false."; exit 1
fi
if [ "$AM" != "false" ]; then
  echo "❌ ServiceAccount 'no-token' has automountServiceAccountToken='$AM' (want false)."; exit 1
fi
# 2+3) Pod 'hardened' must use the SA and have NO SA token volume projected in.
J=$(kubectl -n "$NS" get pod hardened -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Pod 'hardened' not found in $NS. Create it (image busybox:1.36) with serviceAccountName: no-token."; exit 1; }
export J
python3 - <<'PY'
import os,json,sys
p=json.loads(os.environ['J'])
spec=p.get("spec",{})
def fail(m): print("❌ "+m); sys.exit(1)
if spec.get("serviceAccountName")!="no-token":
    fail("Pod 'hardened' uses serviceAccount '%s' (want no-token)."%spec.get("serviceAccountName"))
# No projected SA token volume, and no SA token volumeMount, should be present.
for v in (spec.get("volumes") or []):
    if v.get("name","").startswith("kube-api-access") or (v.get("projected") and any(
        (s.get("serviceAccountToken") is not None) for s in (v["projected"].get("sources") or []))):
        fail("Pod 'hardened' still has a ServiceAccount token volume (%s). Disable automount on the SA (or set automountServiceAccountToken:false on the pod)."%v.get("name"))
for c in (spec.get("containers") or []):
    for m in (c.get("volumeMounts") or []):
        if m.get("mountPath")=="/var/run/secrets/kubernetes.io/serviceaccount":
            fail("Pod 'hardened' still mounts a ServiceAccount token at %s."%m["mountPath"])
print("✅ SA 'no-token' has automount disabled and pod 'hardened' uses it with no token mounted")
PY
