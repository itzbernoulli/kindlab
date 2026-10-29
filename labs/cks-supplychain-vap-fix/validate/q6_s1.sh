#!/bin/bash
POL=no-latest-tag
BIND=no-latest-tag-binding
J=$(kubectl get validatingadmissionpolicy "$POL" -o json 2>/dev/null); [ -z "$J" ] && { echo "❌ ValidatingAdmissionPolicy '$POL' not found. Create it with a CEL rule rejecting images ending in :latest."; exit 1; }
B=$(kubectl get validatingadmissionpolicybinding "$BIND" -o json 2>/dev/null); [ -z "$B" ] && { echo "❌ ValidatingAdmissionPolicyBinding '$BIND' not found. Bind the policy with validationActions: [Deny]."; exit 1; }
export J B
python3 - <<'PY'
import os,json,sys
pol=json.loads(os.environ['J']); b=json.loads(os.environ['B'])
def fail(m): print("❌ "+m); sys.exit(1)
exprs=" ".join(v.get("expression","") for v in (pol["spec"].get("validations") or []))
if ":latest" not in exprs: fail("policy '%s' has no validation referencing ':latest' (got %r)"%("no-latest-tag",exprs or "none"))
if "endsWith" not in exprs: fail("policy validation should use endsWith(':latest') over object.spec.containers (got %r)"%(exprs or "none"))
if "spec.containers" not in exprs: fail("policy validation does not inspect object.spec.containers (got %r)"%(exprs or "none"))
if b["spec"].get("policyName")!="no-latest-tag": fail("binding policyName is %r, expected 'no-latest-tag'"%b["spec"].get("policyName"))
if "Deny" not in (b["spec"].get("validationActions") or []): fail("binding validationActions %r does not include Deny"%(b["spec"].get("validationActions")))
print("✅ VAP no-latest-tag + binding ban :latest with Deny")
PY
