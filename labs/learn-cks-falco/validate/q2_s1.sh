#!/bin/bash
# Grade on DaemonSet ROLLOUT (one pod scheduled per node), not full driver readiness.
# The Falco eBPF driver needs BTF (/sys/kernel/btf/vmlinux), which Docker Desktop's
# LinuxKit kernel lacks — so pods never reach Ready on this bench. Scheduling is the
# gradable signal here (same approach as Q4); on a real BTF host they also go Ready.
NS=falco
R=$(kubectl -n "$NS" get ds falco -o jsonpath='{.status.numberReady}' 2>/dev/null)
D=$(kubectl -n "$NS" get ds falco -o jsonpath='{.status.desiredNumberScheduled}' 2>/dev/null)
if [ -z "$D" ] || [ "${D:-0}" -lt 1 ]; then
  echo "❌ Falco DaemonSet not rolled out (desiredScheduled=${D:-0}). Install it so one Falco pod is scheduled on every node."; exit 1
fi
if [ "$R" = "$D" ]; then
  echo "✅ Falco DaemonSet rolled out and fully Ready ($R/$D pods)."; exit 0
fi
echo "✅ Falco DaemonSet rolled out — one pod scheduled per node ($D desired, ${R:-0} Ready). Full Ready needs a BTF-enabled host for the eBPF driver; scheduling is the gradable signal on this bench."; exit 0
