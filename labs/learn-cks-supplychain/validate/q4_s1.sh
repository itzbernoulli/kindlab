#!/bin/bash
POL=approved-registry
BIND=approved-registry-binding
kubectl get validatingadmissionpolicy "$POL" >/dev/null 2>&1 || { echo "❌ ValidatingAdmissionPolicy '$POL' not found. Create it with a CEL rule requiring registry.k8s.io."; exit 1; }
EXPR=$(kubectl get validatingadmissionpolicy "$POL" -o jsonpath='{.spec.validations[*].expression}' 2>/dev/null)
echo "$EXPR" | grep -q 'registry.k8s.io' || { echo "❌ policy '$POL' has no validation referencing 'registry.k8s.io' (got '${EXPR:-none}'). Add a CEL check on object.spec.containers images."; exit 1; }
echo "$EXPR" | grep -q 'spec.containers' || { echo "❌ policy '$POL' validation does not inspect object.spec.containers (got '${EXPR:-none}')."; exit 1; }
kubectl get validatingadmissionpolicybinding "$BIND" >/dev/null 2>&1 || { echo "❌ ValidatingAdmissionPolicyBinding '$BIND' not found. Bind the policy with validationActions: [Deny]."; exit 1; }
PN=$(kubectl get validatingadmissionpolicybinding "$BIND" -o jsonpath='{.spec.policyName}' 2>/dev/null)
[ "$PN" = "$POL" ] || { echo "❌ binding '$BIND' references policyName='${PN:-none}', expected '$POL'."; exit 1; }
VA=$(kubectl get validatingadmissionpolicybinding "$BIND" -o jsonpath='{.spec.validationActions[*]}' 2>/dev/null)
echo "$VA" | grep -q 'Deny' || { echo "❌ binding '$BIND' does not Deny (validationActions='${VA:-none}'). Set validationActions: [Deny]."; exit 1; }
echo "✅ VAP approved-registry + binding exist with the registry.k8s.io rule"
exit 0
