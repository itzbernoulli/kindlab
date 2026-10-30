#!/bin/bash
BIND=block-privileged-binding
POL=block-privileged
kubectl get validatingadmissionpolicy "$POL" >/dev/null 2>&1 || { echo "❌ policy '$POL' not found (don't delete it — fix the binding to point at it)"; exit 1; }
B=$(kubectl get validatingadmissionpolicybinding "$BIND" -o json 2>/dev/null); [ -z "$B" ] && { echo "❌ binding '$BIND' not found (don't delete it — fix its policyName and validationActions)"; exit 1; }; export B
python3 - <<'PY'
import os,json,sys
b=json.loads(os.environ['B'])["spec"]
def fail(m): print("❌ "+m); sys.exit(1)
if b.get("policyName")!="block-privileged": fail("binding policyName is %r — must point at the real policy 'block-privileged'"%b.get("policyName"))
if "Deny" not in (b.get("validationActions") or []): fail("binding validationActions %r does not include Deny — it enforces nothing"%(b.get("validationActions")))
print("✅ block-privileged-binding now targets block-privileged with Deny")
PY
