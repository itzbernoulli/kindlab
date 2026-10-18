#!/bin/bash
# Reset the learn environment to a clean slate. Idempotent; never breaks the cluster.
# Make sure both workers are schedulable (a prior run may have left $W2 cordoned/drained).
kubectl uncordon "$W1" >/dev/null 2>&1
kubectl uncordon "$W2" >/dev/null 2>&1
# Remove any leftover artifacts from the steps.
kubectl delete pod drain-me -n default --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
docker exec "$CP" rm -f /tmp/versions.txt /tmp/serverversion.txt >/dev/null 2>&1
echo "learn-cka-kubeadm reset (both workers schedulable, scratch files cleared)"
