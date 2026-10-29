#!/bin/bash
J=$(kubectl -n runtimeclass-learn get pod brokenrc -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ pod 'brokenrc' not found — recreate it with a valid runtimeClassName gvisor."; exit 1; }; export J
# The target class must actually exist, else the 'fix' points at nothing.
kubectl get runtimeclass gvisor >/dev/null 2>&1 || { echo "❌ RuntimeClass 'gvisor' does not exist — create it (step 1) so brokenrc can reference a real class."; exit 1; }
python3 - <<'PY'
import os,json,sys
sp=json.loads(os.environ['J'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
rc=sp.get("runtimeClassName")
if rc!="gvisor": fail("brokenrc.spec.runtimeClassName must be a valid existing class 'gvisor' (got %r — the seeded typo was 'gvisro')"%rc)
imgs=[c.get("image") for c in sp.get("containers",[])]
if "busybox:1.36" not in imgs: fail("keep container image busybox:1.36 (got %r)"%imgs)
print("✅ 'brokenrc' references a valid existing RuntimeClass (gvisor) — typo fixed")
PY
