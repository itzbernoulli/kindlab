#!/bin/bash
# Seed the preemption scenario: two 'given' PriorityClasses (demo-low/demo-high),
# label $W1, and fill it with two low-priority ballast pods pinned there so a new
# high-priority pod can only land by preempting one.
NS=priority-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl create priorityclass demo-low  --value=100     2>/dev/null
kubectl create priorityclass demo-high --value=1000000 2>/dev/null
[ -n "$W1" ] && kubectl label node "$W1" prio-demo=yes --overwrite >/dev/null 2>&1
kubectl -n "$NS" delete pod vip ballast-0 ballast-1 --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
for i in 0 1; do
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<YAML
apiVersion: v1
kind: Pod
metadata: { name: ballast-$i, namespace: $NS, labels: { role: ballast } }
spec:
  priorityClassName: demo-low
  nodeSelector: { prio-demo: "yes" }
  containers:
  - name: web
    image: nginx:1.25
    resources: { requests: { cpu: 1500m } }
YAML
done
echo "seeded 2 low-priority ballast pods filling $W1 (demo-low). Create a demo-high pod 'vip' to preempt one."
