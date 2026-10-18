#!/bin/bash
# DaemonSet node-agent must schedule one ready pod on EVERY node, including the control plane.
NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c .)
DESIRED=$(kubectl -n sched-learn get ds node-agent -o jsonpath='{.status.desiredNumberScheduled}' 2>/dev/null)
READY=$(kubectl -n sched-learn get ds node-agent -o jsonpath='{.status.numberReady}' 2>/dev/null)

if [ -z "$DESIRED" ]; then
  echo "❌ DaemonSet node-agent not found in sched-learn. Create it with image busybox:1.36 and a broad toleration."; exit 1
fi
if [ "$NODES" -lt 1 ]; then
  echo "❌ could not count cluster nodes. Check cluster connectivity."; exit 1
fi
if [ "$DESIRED" != "$NODES" ]; then
  echo "❌ node-agent is scheduled on $DESIRED of $NODES nodes. Add 'tolerations: [{operator: Exists}]' so it also covers the control-plane node."; exit 1
fi
if [ "$READY" != "$NODES" ]; then
  echo "❌ node-agent has $READY/$NODES pods ready. Wait for all pods to start, or check the image/command."; exit 1
fi
echo "✅ DaemonSet node-agent runs one ready pod on all $NODES nodes"; exit 0
