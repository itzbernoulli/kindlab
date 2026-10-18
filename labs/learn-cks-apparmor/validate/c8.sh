#!/bin/bash
# Diagnose & fix: the missing profile 'k8s-audit-write' must now be written on $W1 with the
# right profile name + deny-write rule, AND pod 'broken-aa' must still reference it (don't rebuild).
NS=cks-apparmor
F=/etc/apparmor.d/k8s-audit-write

if ! docker exec "$W1" test -f "$F" 2>/dev/null; then
  echo "❌ $F not found on $W1 — 'broken-aa' references k8s-audit-write but it was never written. Create + load it."; exit 1
fi
if ! docker exec "$W1" grep -q 'profile k8s-audit-write' "$F" 2>/dev/null; then
  echo "❌ $F has no 'profile k8s-audit-write' declaration (the profile NAME must match what the pod references)."; exit 1
fi
if ! docker exec "$W1" grep -Eq 'deny[[:space:]]+/etc/secret-data/.*[[:space:]]+w' "$F" 2>/dev/null; then
  echo "❌ $F has no 'deny /etc/secret-data/** w,' rule."; exit 1
fi

J=$(kubectl -n "$NS" get pod broken-aa -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ pod 'broken-aa' not found — don't delete it; fix the node profile."; exit 1; }
export J
python3 - <<'PY'
import os,json,sys
p=json.loads(os.environ['J']); c=next((x for x in p["spec"].get("containers",[]) if x.get("name")=="hello"),None) or {}
aa=(c.get("securityContext") or {}).get("appArmorProfile") or {}
ann=(p["metadata"].get("annotations") or {}).get("container.apparmor.security.beta.kubernetes.io/hello")
ok=(aa.get("type")=="Localhost" and aa.get("localhostProfile")=="k8s-audit-write") or ann=="localhost/k8s-audit-write"
if not ok:
    print("❌ 'broken-aa' no longer references k8s-audit-write — fix the node profile, not the pod reference."); sys.exit(1)
print("✅ k8s-audit-write written on the node AND broken-aa still references it — missing profile resolved"); sys.exit(0)
PY
