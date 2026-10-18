#!/bin/bash
# Step 5 start: ensure namespace exists, all nodes schedulable (uncordon), and remove
# the lab's custom NoSchedule taint so node count is predictable. The control-plane's
# built-in taint stays — the learner's DaemonSet must tolerate it with operator: Exists.
kubectl create namespace sched-learn >/dev/null 2>&1
for N in "$W1" "$W2"; do
  [ -n "$N" ] || continue
  kubectl uncordon "$N" >/dev/null 2>&1
  kubectl taint node "$N" workload=batch:NoSchedule- >/dev/null 2>&1
  kubectl taint node "$N" workload:NoSchedule- >/dev/null 2>&1
done
kubectl -n sched-learn delete daemonset node-agent --ignore-not-found --wait=false >/dev/null 2>&1
echo "step 5 ready: create DaemonSet node-agent that runs one pod on EVERY node (tolerate the control-plane taint)"
