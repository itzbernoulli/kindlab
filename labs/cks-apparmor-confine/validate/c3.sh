#!/bin/bash
# The captured write attempt inside 'confined' must show a denial, AND 'confined' must still
# be bound to k8s-deny-write (no grading contradiction — Step 2 state persists).
NS=cks-apparmor

R=$(kubectl -n "$NS" get configmap apparmor-proof -o jsonpath='{.data.result}' 2>/dev/null)
if [ -z "$R" ]; then
  echo "❌ ConfigMap 'apparmor-proof' (key 'result') missing. Capture the write attempt inside 'confined'."; exit 1
fi
if ! echo "$R" | grep -qi "permission denied"; then
  echo "❌ result shows no denial ('$R'). On an AppArmor host 'touch /etc/secret-data/x' is 'Permission denied'; write to the PROTECTED path, not /tmp."; exit 1
fi

# 'confined' must still reference k8s-deny-write.
J=$(kubectl -n "$NS" get pod confined -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ pod 'confined' not found — keep the Step 2 pod intact."; exit 1; }
export J
python3 - <<'PY'
import os,json,sys
p=json.loads(os.environ['J']); c=next((x for x in p["spec"].get("containers",[]) if x.get("name")=="hello"),None) or {}
aa=(c.get("securityContext") or {}).get("appArmorProfile") or {}
ann=(p["metadata"].get("annotations") or {}).get("container.apparmor.security.beta.kubernetes.io/hello")
ok=(aa.get("type")=="Localhost" and aa.get("localhostProfile")=="k8s-deny-write") or ann=="localhost/k8s-deny-write"
if not ok:
    print("❌ 'confined' no longer references k8s-deny-write — keep the Step 2 pod intact."); sys.exit(1)
print("✅ write inside 'confined' was denied AND the pod is still bound to k8s-deny-write"); sys.exit(0)
PY
