#!/bin/bash
# Step 1: the control plane must be upgraded to the target version (kube-apiserver
# static pod image == target). Target is whatever the main cluster runs.
SCRATCH="${SCRATCH:-kindlab-upgrade}"
SNODE="${SCRATCH_NODE:-$SCRATCH-control-plane}"
KC="${SCRATCH_KUBECONFIG:-$(dirname "$KUBECONFIG")/$SCRATCH.kubeconfig}"
MAINCP="${CP:-kindlab-control-plane}"
TGT=$(docker exec "$MAINCP" kubeadm version -o short 2>/dev/null)
IMG=$(kubectl --kubeconfig "$KC" -n kube-system get pod "kube-apiserver-$SNODE" -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)
case "$IMG" in
  *":$TGT") echo "✅ control plane upgraded — kube-apiserver at $TGT"; exit 0 ;;
esac
echo "❌ control plane not at $TGT yet (apiserver image='${IMG:-none}'). On $SNODE: install the new kubeadm (cp /opt/k136/kubeadm /usr/bin/kubeadm), then run: kubeadm upgrade apply $TGT -y"
exit 1
