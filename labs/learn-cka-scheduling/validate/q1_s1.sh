#!/bin/bash
# ssd-pod must be Running, on a node that carries disktype=ssd, and have the nodeSelector.
PHASE=$(kubectl -n sched-learn get pod ssd-pod -o jsonpath='{.status.phase}' 2>/dev/null)
NODE=$(kubectl -n sched-learn get pod ssd-pod -o jsonpath='{.spec.nodeName}' 2>/dev/null)
SEL=$(kubectl -n sched-learn get pod ssd-pod -o jsonpath='{.spec.nodeSelector.disktype}' 2>/dev/null)

if [ -z "$NODE" ]; then
  echo "❌ ssd-pod not found or not scheduled (phase='${PHASE:-none}'). Label a node disktype=ssd and create the pod with nodeSelector disktype=ssd."; exit 1
fi
if [ "$SEL" != "ssd" ]; then
  echo "❌ ssd-pod has no nodeSelector disktype=ssd (got '${SEL:-none}'). It must land there via nodeSelector, not by chance."; exit 1
fi
LAB=$(kubectl get node "$NODE" -o jsonpath='{.metadata.labels.disktype}' 2>/dev/null)
if [ "$LAB" != "ssd" ]; then
  echo "❌ node '$NODE' running ssd-pod is not labeled disktype=ssd. Label the target node: kubectl label node $NODE disktype=ssd"; exit 1
fi
if [ "$PHASE" != "Running" ]; then
  echo "❌ ssd-pod is '${PHASE:-Pending}', not Running. Ensure a node is labeled disktype=ssd so it can schedule."; exit 1
fi
echo "✅ ssd-pod is Running on '$NODE' (disktype=ssd) via nodeSelector"; exit 0
