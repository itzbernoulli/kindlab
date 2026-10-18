#!/bin/bash
POL=approved-registry
BIND=approved-registry-binding
J=$(kubectl get validatingadmissionpolicy "$POL" -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ ValidatingAdmissionPolicy '$POL' not found. Create it with a CEL rule requiring registry.k8s.io over object.spec.containers."; exit 1; }
B=$(kubectl get validatingadmissionpolicybinding "$BIND" -o json 2>/dev/null); [ -z "$B" ] && { echo "❌ ValidatingAdmissionPolicyBinding '$BIND' not found. Bind the policy with validationActions: [Deny]."; exit 1; }
export J B
python3 - <<'PY'
import os,json,sys
pol=json.loads(os.environ['J']); b=json.loads(os.environ['B'])
def fail(m): print("❌ "+m); sys.exit(1)
exprs=" ".join(v.get("expression","") for v in (pol["spec"].get("validations") or []))
if "registry.k8s.io" not in exprs: fail("policy 'approved-registry' has no validation referencing 'registry.k8s.io' (got %r)"%(exprs or "none"))
if "spec.containers" not in exprs: fail("policy validation does not inspect object.spec.containers (got %r)"%(exprs or "none"))
if b["spec"].get("policyName")!="approved-registry": fail("binding policyName is %r, expected 'approved-registry'"%b["spec"].get("policyName"))
if "Deny" not in (b["spec"].get("validationActions") or []): fail("binding validationActions %r does not include Deny"%(b["spec"].get("validationActions")))
print("✅ VAP approved-registry + binding enforce the registry.k8s.io rule with Deny")
PY
