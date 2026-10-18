#!/bin/bash
NS=svcnet-learn
kubectl -n $NS get networkpolicy default-deny >/dev/null 2>&1 || { echo "❌ NetworkPolicy 'default-deny' not found in $NS."; exit 1; }
# podSelector must be empty (selects all pods): no matchLabels and no matchExpressions
ML=$(kubectl -n $NS get networkpolicy default-deny -o jsonpath='{.spec.podSelector.matchLabels}' 2>/dev/null)
ME=$(kubectl -n $NS get networkpolicy default-deny -o jsonpath='{.spec.podSelector.matchExpressions}' 2>/dev/null)
if [ -n "$ML" ] && [ "$ML" != "{}" ]; then echo "❌ podSelector is not empty (matchLabels='$ML'); must select ALL pods ({})."; exit 1; fi
if [ -n "$ME" ] && [ "$ME" != "[]" ]; then echo "❌ podSelector has matchExpressions; must be empty to select ALL pods."; exit 1; fi
# policyTypes must include Ingress
PT=$(kubectl -n $NS get networkpolicy default-deny -o jsonpath='{.spec.policyTypes[*]}' 2>/dev/null)
echo "$PT" | grep -qw Ingress || { echo "❌ policyTypes is '$PT', must include Ingress."; exit 1; }
# must NOT allow Egress (default-deny ingress only)
echo "$PT" | grep -qw Egress && { echo "❌ policyTypes includes Egress; this step is ingress-only default-deny."; exit 1; }
# there must be NO ingress rules (deny all)
RULES=$(kubectl -n $NS get networkpolicy default-deny -o jsonpath='{.spec.ingress}' 2>/dev/null)
if [ -n "$RULES" ] && [ "$RULES" != "[]" ]; then echo "❌ ingress rules present ('$RULES'); default-deny means NO ingress rules."; exit 1; fi
echo "✅ NetworkPolicy default-deny: empty podSelector, policyTypes=[Ingress], no ingress rules"
exit 0
