#!/bin/bash
# Step 2: the kubelet on the node must be upgraded to the target version.
SCRATCH="${SCRATCH:-kindlab-upgrade}"
SNODE="${SCRATCH_NODE:-$SCRATCH-control-plane}"
KC="${SCRATCH_KUBECONFIG:-$(dirname "$KUBECONFIG")/$SCRATCH.kubeconfig}"
MAINCP="${CP:-kindlab-control-plane}"
TGT=$(docker exec "$MAINCP" kubeadm version -o short 2>/dev/null)
V=$(kubectl --kubeconfig "$KC" get node "$SNODE" -o jsonpath='{.status.nodeInfo.kubeletVersion}' 2>/dev/null)
if [ "$V" = "$TGT" ]; then echo "✅ kubelet upgraded to $TGT on $SNODE"; exit 0; fi
echo "❌ kubelet at '${V:-unknown}', expected $TGT. On $SNODE: install the new kubelet (cp /opt/k136/kubelet /usr/bin/kubelet), then: systemctl daemon-reload && systemctl restart kubelet"
exit 1
