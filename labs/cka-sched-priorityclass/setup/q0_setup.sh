#!/bin/bash
# Prepare priority-learn. Delete the cluster-scoped PriorityClasses this lab
# creates/seeds, clean the namespace's pods, and remove the demo node label.
NS=priority-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete pod important vip ballast-0 ballast-1 --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
for pc in high-priority low-priority demo-high demo-low; do kubectl delete priorityclass "$pc" --ignore-not-found >/dev/null 2>&1; done
[ -n "$W1" ] && kubectl label node "$W1" prio-demo- >/dev/null 2>&1
echo "priority-learn ready (PriorityClasses + pods cleared, $W1 unlabeled)"
