#!/bin/bash
# Step 1: the snapshot must be restored into the NEW data dir /var/lib/etcd/restored.
SCRATCH="${SCRATCH:-kindlab-etcd}"
NODE="${SCRATCH_NODE:-$SCRATCH-control-plane}"
if docker exec "$NODE" test -f /var/lib/etcd/restored/member/snap/db 2>/dev/null; then
  echo "✅ snapshot restored into /var/lib/etcd/restored (member/ present)"
  exit 0
fi
echo "❌ no restored etcd data at /var/lib/etcd/restored on $NODE. Restore the snapshot: kubectl -n kube-system exec <etcd-pod> -- etcdutl snapshot restore /var/lib/etcd/snap.db --data-dir /var/lib/etcd/restored (use this lab's kubeconfig)."
exit 1
