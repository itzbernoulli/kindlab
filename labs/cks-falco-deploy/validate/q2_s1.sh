#!/bin/bash
# Strict rollout: the Falco DaemonSet must be scheduled on EVERY node, i.e.
# desiredNumberScheduled == cluster node count. Full Ready needs a BTF host for
# the eBPF probe (this bench lacks it), so scheduling is the graded signal.
NS=falco
NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
D=$(kubectl -n "$NS" get ds falco -o jsonpath='{.status.desiredNumberScheduled}' 2>/dev/null)
C=$(kubectl -n "$NS" get ds falco -o jsonpath='{.status.currentNumberScheduled}' 2>/dev/null)
R=$(kubectl -n "$NS" get ds falco -o jsonpath='{.status.numberReady}' 2>/dev/null)
if [ -z "$D" ]; then
  echo "❌ Falco DaemonSet 'falco' not found in namespace '$NS'. Install it first"; exit 1
fi
if [ "${NODES:-0}" -lt 1 ]; then
  echo "❌ could not determine the cluster node count"; exit 1
fi
if [ "${D:-0}" -ne "${NODES}" ]; then
  echo "❌ Falco scheduled on ${D:-0}/${NODES} nodes — the DaemonSet must target every node (desiredNumberScheduled=${NODES})"; exit 1
fi
if [ "${C:-0}" -ne "${NODES}" ]; then
  echo "❌ Falco desired=${D} but only ${C:-0}/${NODES} pods actually scheduled. Check node taints/tolerations"; exit 1
fi
if [ "${R:-0}" = "${D}" ]; then
  echo "✅ Falco DaemonSet rolled out and fully Ready (${R}/${D} pods, one per node)"; exit 0
fi
echo "✅ Falco DaemonSet scheduled on every node (${D}/${NODES} desired, ${C} scheduled, ${R:-0} Ready). Full Ready needs a BTF-enabled host for the eBPF driver; scheduling is the graded signal on this bench"; exit 0
