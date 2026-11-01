#!/bin/bash
# Real kubeadm upgrade drill on THIS lab's throwaway cluster. The harness
# provisions 'kindlab-upgrade' pinned one minor BELOW the target (kindest/node:v1.35.0).
# We STAGE the target-version binaries at /opt/k136 on the scratch node — sourced
# from the MAIN cluster's node, which already runs the target version. On kind this
# stands in for the `apt-get install kubeadm/kubelet=<ver>` you'd run in the exam.
# MAINTENANCE: if the kind default moves beyond v1.36, bump the scratchCluster image
# in lab.json to one minor below it (the target is derived from the main cluster).
SCRATCH="${SCRATCH:-kindlab-upgrade}"
SNODE="${SCRATCH_NODE:-$SCRATCH-control-plane}"
KC="${SCRATCH_KUBECONFIG:-$(dirname "$KUBECONFIG")/$SCRATCH.kubeconfig}"
MAINCP="${CP:-kindlab-control-plane}"
k(){ kubectl --kubeconfig "$KC" "$@"; }

for i in $(seq 1 45); do k get nodes >/dev/null 2>&1 && break; sleep 2; done

# stage the target-version binaries (from the main cluster node) onto the scratch node
TMP=$(mktemp -d)
for b in kubeadm kubelet kubectl; do docker cp "$MAINCP:/usr/bin/$b" "$TMP/$b" >/dev/null 2>&1; done
docker exec "$SNODE" mkdir -p /opt/k136 >/dev/null 2>&1
for b in kubeadm kubelet kubectl; do docker cp "$TMP/$b" "$SNODE:/opt/k136/$b" >/dev/null 2>&1; done
docker exec "$SNODE" chmod +x /opt/k136/kubeadm /opt/k136/kubelet /opt/k136/kubectl >/dev/null 2>&1
rm -rf "$TMP"

TGT=$(docker exec "$MAINCP" kubeadm version -o short 2>/dev/null)
echo "kubeadm upgrade lab ready on '$SCRATCH' (at v1.35.0). Target $TGT binaries staged at /opt/k136 on $SNODE. Point kubectl at: $KC"
