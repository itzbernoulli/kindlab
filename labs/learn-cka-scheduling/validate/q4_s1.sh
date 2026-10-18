#!/bin/bash
# manual-pod must be Running and bound to $W2 via spec.nodeName (no scheduler involved).
PHASE=$(kubectl -n sched-learn get pod manual-pod -o jsonpath='{.status.phase}' 2>/dev/null)
NODE=$(kubectl -n sched-learn get pod manual-pod -o jsonpath='{.spec.nodeName}' 2>/dev/null)
if [ -z "$NODE" ]; then
  echo "❌ manual-pod not found. Create it with spec.nodeName set to '$W2'."; exit 1
fi
if [ "$NODE" != "$W2" ]; then
  echo "❌ manual-pod is bound to '$NODE', not '$W2'. Set spec.nodeName: $W2 in the pod spec."; exit 1
fi
if [ "$PHASE" != "Running" ]; then
  echo "❌ manual-pod is '${PHASE:-Pending}', not Running on '$W2'. Confirm the node name is correct and schedulable."; exit 1
fi
echo "✅ manual-pod is Running, pinned to '$W2' via nodeName (scheduler bypassed)"; exit 0
