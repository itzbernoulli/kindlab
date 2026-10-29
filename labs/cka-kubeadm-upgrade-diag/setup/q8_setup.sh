#!/bin/bash
# Step 8 (diagnose & fix): seed a Pod that stays Pending because the only node it can
# land on ($W1) is cordoned. The learner must diagnose (describe pod / get nodes) and
# uncordon $W1 so the pod schedules. End state: $W1 schedulable + maint-app Running.
#
# We pin the pod with a UNIQUE node label (not nodeName — nodeName would bypass the
# scheduler and bind even to a cordoned node, hiding the fault). nodeSelector forces
# the scheduler to pick $W1, which is unschedulable -> Pending until uncordoned.

LBL=kindlab-maint
kubectl label node "$W1" "$LBL=target" --overwrite >/dev/null 2>&1

# Remove any leftover pod, then cordon $W1 (the seeded fault) and seed the Pending pod.
kubectl -n default delete pod maint-app --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl cordon "$W1" >/dev/null 2>&1

cat <<YAML | kubectl apply -f - >/dev/null 2>&1
apiVersion: v1
kind: Pod
metadata:
  name: maint-app
  namespace: default
  labels:
    app: maint-app
spec:
  nodeSelector:
    $LBL: target
  containers:
  - name: c
    image: busybox:1.36
    command: ["sh","-c","sleep 100000"]
YAML
echo "seeded Pending Pod maint-app (pinned to $W1, which is cordoned — diagnose & fix in step 8)"
