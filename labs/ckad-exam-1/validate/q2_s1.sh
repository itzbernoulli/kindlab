#!/bin/bash
NS=exam
IMG=$(kubectl -n $NS get deploy roller -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
if [ -z "$IMG" ]; then echo "❌ Deployment 'roller' not found in namespace $NS"; exit 1; fi
if [ "$IMG" != "nginx:1.25" ]; then echo "❌ roller image is '$IMG', expected nginx:1.25 (update + roll out)"; exit 1; fi
SPEC=$(kubectl -n $NS get deploy roller -o jsonpath='{.spec.replicas}' 2>/dev/null)
UPD=$(kubectl -n $NS get deploy roller -o jsonpath='{.status.updatedReplicas}' 2>/dev/null)
AVAIL=$(kubectl -n $NS get deploy roller -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "${UPD:-0}" != "$SPEC" ] || [ "${AVAIL:-0}" != "$SPEC" ]; then
  echo "❌ rollout incomplete: updated=${UPD:-0} available=${AVAIL:-0} of $SPEC"; exit 1
fi
echo "✅ roller rolled out to nginx:1.25 ($SPEC/$SPEC updated & available)"; exit 0
