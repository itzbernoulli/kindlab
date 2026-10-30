#!/bin/bash
# Reset the learn environment to a clean slate. Idempotent; never breaks the cluster.
# Resource-level cleanup only (NO namespace deletes — that races under load and wipes the lab).

# Make sure both workers are schedulable (a prior run may have left one cordoned/drained).
kubectl uncordon "$W1" >/dev/null 2>&1
kubectl uncordon "$W2" >/dev/null 2>&1

# Remove leftover pods from the steps (resource-level, --ignore-not-found).
kubectl -n default delete pod drain-me maint-app --ignore-not-found --force --grace-period=0 >/dev/null 2>&1

# Clear scratch files the steps write onto $CP.
docker exec "$CP" rm -f /tmp/versions.txt /tmp/cgroupdriver.txt /tmp/apiserver-image.txt /tmp/serverversion.txt >/dev/null 2>&1

echo "learn-cka-kubeadm reset (both workers schedulable, step pods removed, scratch files cleared)"
