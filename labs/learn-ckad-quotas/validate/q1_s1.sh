#!/bin/bash
NS=quota-compute; Q=compute-quota
RC=$(kubectl get resourcequota $Q -n $NS -o jsonpath='{.spec.hard.requests\.cpu}' 2>/dev/null)
RM=$(kubectl get resourcequota $Q -n $NS -o jsonpath='{.spec.hard.requests\.memory}' 2>/dev/null)
LC=$(kubectl get resourcequota $Q -n $NS -o jsonpath='{.spec.hard.limits\.cpu}' 2>/dev/null)
LM=$(kubectl get resourcequota $Q -n $NS -o jsonpath='{.spec.hard.limits\.memory}' 2>/dev/null)
if [ "$RC" = "1" ] && [ "$RM" = "1Gi" ] && [ "$LC" = "2" ] && [ "$LM" = "2Gi" ]; then echo "✅ compute-quota hard = requests 1/1Gi, limits 2/2Gi"; exit 0; fi
echo "❌ compute-quota hard values off (requests.cpu='$RC' requests.memory='$RM' limits.cpu='$LC' limits.memory='$LM'; want 1/1Gi/2/2Gi)"; exit 1
