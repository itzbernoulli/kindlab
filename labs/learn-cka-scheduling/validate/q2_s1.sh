#!/bin/bash
# $W1 must carry the workload=batch:NoSchedule taint, and batch-pod must be Running on $W1
# with a matching toleration (proving the toleration let it past the taint).
TAINT=$(kubectl get node "$W1" -o jsonpath='{range .spec.taints[?(@.key=="workload")]}{.value}:{.effect}{end}' 2>/dev/null)
if [ "$TAINT" != "batch:NoSchedule" ]; then
  echo "❌ node '$W1' is not tainted workload=batch:NoSchedule (got '${TAINT:-none}'). Run: kubectl taint node $W1 workload=batch:NoSchedule"; exit 1
fi

PHASE=$(kubectl -n sched-learn get pod batch-pod -o jsonpath='{.status.phase}' 2>/dev/null)
NODE=$(kubectl -n sched-learn get pod batch-pod -o jsonpath='{.spec.nodeName}' 2>/dev/null)
if [ -z "$NODE" ]; then
  echo "❌ batch-pod not found or not scheduled (phase='${PHASE:-none}'). It needs a toleration for workload=batch:NoSchedule and must target '$W1'."; exit 1
fi
if [ "$NODE" != "$W1" ]; then
  echo "❌ batch-pod is on '$NODE', not the tainted node '$W1'. Use nodeSelector/affinity so it targets '$W1'."; exit 1
fi
# Confirm the pod actually declares a matching toleration (not just a scheduler coincidence).
TOL=$(kubectl -n sched-learn get pod batch-pod -o jsonpath='{range .spec.tolerations[?(@.key=="workload")]}{.value}{end}' 2>/dev/null)
if [ "$TOL" != "batch" ]; then
  echo "❌ batch-pod has no toleration for key 'workload' value 'batch'. Add tolerations: key=workload value=batch effect=NoSchedule."; exit 1
fi
if [ "$PHASE" != "Running" ]; then
  echo "❌ batch-pod is '${PHASE:-Pending}', not Running on '$W1'. Check the toleration matches the taint exactly."; exit 1
fi
echo "✅ '$W1' is tainted and batch-pod tolerates it and runs there"; exit 0
