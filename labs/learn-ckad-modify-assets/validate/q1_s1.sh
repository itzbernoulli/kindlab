#!/bin/bash
NS=modify-learn
if ! kubectl -n $NS get deploy legacy >/dev/null 2>&1; then echo "❌ deployment 'legacy' not found in $NS (recreate it with the new label)"; exit 1; fi
SEL=$(kubectl -n $NS get deploy legacy -o jsonpath='{.spec.selector.matchLabels.app}' 2>/dev/null)
TMPL=$(kubectl -n $NS get deploy legacy -o jsonpath='{.spec.template.metadata.labels.app}' 2>/dev/null)
AVL=$(kubectl -n $NS get deploy legacy -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "$SEL" != "payments" ]; then echo "❌ legacy selector app is '${SEL}', expected 'payments'. .spec.selector is immutable — delete and recreate with selector app=payments (kubectl replace --force)"; exit 1; fi
if [ "$TMPL" != "payments" ]; then echo "❌ legacy pod-template label app is '${TMPL}', expected 'payments' (must match the new selector)"; exit 1; fi
if [ "${AVL:-0}" -lt 1 ]; then echo "❌ legacy has no available replicas yet"; exit 1; fi
echo "✅ 'legacy' recreated with selector+pods relabeled app=payments (selector is immutable, so in-place edit can't do this)"; exit 0
