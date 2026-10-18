#!/bin/bash
# Require BOTH: the kubelet is actually running on the node AND the node is Ready.
# (Checking Ready alone is gameable — after `systemctl stop kubelet` the node stays
#  Ready for ~40s before the control plane marks it NotReady, so the kubelet-active
#  check catches the broken seed immediately.)
KUBELET=$(docker exec "$W1" systemctl is-active kubelet 2>/dev/null)
if [ "$KUBELET" != "active" ]; then
  echo "❌ kubelet on '$W1' is '${KUBELET:-unknown}' (expected active). Restart it: docker exec $W1 systemctl start kubelet"; exit 1
fi
R=$(kubectl get node "$W1" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
if [ "$R" = "True" ]; then echo "✅ kubelet active and node $W1 is Ready"; exit 0; fi
echo "❌ node '$W1' not Ready yet (Ready='${R:-unknown}') — kubelet is active; give it a few seconds."; exit 1
