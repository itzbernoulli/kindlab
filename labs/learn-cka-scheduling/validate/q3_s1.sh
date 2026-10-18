#!/bin/bash
# affinity-pod must be Running on the node labeled tier=gold AND actually declare
# requiredDuringScheduling nodeAffinity matching tier=gold.
PHASE=$(kubectl -n sched-learn get pod affinity-pod -o jsonpath='{.status.phase}' 2>/dev/null)
NODE=$(kubectl -n sched-learn get pod affinity-pod -o jsonpath='{.spec.nodeName}' 2>/dev/null)
if [ -z "$NODE" ]; then
  echo "❌ affinity-pod not found or not scheduled (phase='${PHASE:-none}'). Create it with required nodeAffinity tier In [gold]."; exit 1
fi

KEY=$(kubectl -n sched-learn get pod affinity-pod -o jsonpath='{.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key}' 2>/dev/null)
VAL=$(kubectl -n sched-learn get pod affinity-pod -o jsonpath='{.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values[0]}' 2>/dev/null)
if [ "$KEY" != "tier" ] || [ "$VAL" != "gold" ]; then
  echo "❌ affinity-pod lacks required nodeAffinity for tier In [gold] (got key='${KEY:-none}' value='${VAL:-none}'). It must use requiredDuringSchedulingIgnoredDuringExecution."; exit 1
fi
LAB=$(kubectl get node "$NODE" -o jsonpath='{.metadata.labels.tier}' 2>/dev/null)
if [ "$LAB" != "gold" ]; then
  echo "❌ affinity-pod landed on '$NODE' which is not labeled tier=gold. nodeAffinity should pin it to the gold node."; exit 1
fi
if [ "$PHASE" != "Running" ]; then
  echo "❌ affinity-pod is '${PHASE:-Pending}', not Running. Ensure a node is labeled tier=gold."; exit 1
fi
echo "✅ affinity-pod is Running on '$NODE' (tier=gold) via required nodeAffinity"; exit 0
