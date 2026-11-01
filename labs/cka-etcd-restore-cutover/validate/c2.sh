#!/bin/bash
# Step 2: after the live cutover (etcd.yaml hostPath repointed to the restored
# dir), etcd serves the restored data and the lost 'canary' returns.
SCRATCH="${SCRATCH:-kindlab-etcd}"
NODE="${SCRATCH_NODE:-$SCRATCH-control-plane}"
KC="${SCRATCH_KUBECONFIG:-$(dirname "$KUBECONFIG")/$SCRATCH.kubeconfig}"
k(){ kubectl --kubeconfig "$KC" "$@"; }

# the manifest's etcd-data hostPath must point at the restored dir
if ! docker exec "$NODE" grep -qE '^[[:space:]]*path:[[:space:]]*/var/lib/etcd/restored$' /etc/kubernetes/manifests/etcd.yaml 2>/dev/null; then
  echo "❌ the live etcd is not cut over yet — repoint the etcd-data hostPath in /etc/kubernetes/manifests/etcd.yaml from /var/lib/etcd to /var/lib/etcd/restored (on $NODE)."
  exit 1
fi

# and the recovered data must actually be served (canary namespace back + marker intact)
MARK=$(k -n canary get configmap canary -o jsonpath='{.data.marker}' 2>/dev/null)
if [ "$MARK" = "keepme" ]; then
  echo "✅ live cutover complete — etcd restored and the 'canary' data is recovered"
  exit 0
fi
echo "❌ canary not recovered yet (marker='${MARK:-missing}'). After repointing the manifest, give the kubelet ~30s to restart etcd on the restored data, then re-check."
exit 1
