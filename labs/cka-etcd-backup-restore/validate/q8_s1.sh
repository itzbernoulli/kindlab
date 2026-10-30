#!/bin/bash
# Confirm the cluster survived: apiserver /healthz is ok, the control-plane node is
# Ready, AND the learner actually performed the restore (so this can't pass on an
# untouched cluster).
if ! docker exec "$CP" test -d /var/lib/etcd/etcd-restore/member 2>/dev/null; then
  echo "❌ no restored data dir found — complete the restore (step 3) before confirming health"; exit 1
fi
HZ=$(kubectl get --raw=/healthz 2>/dev/null)
if [ "$HZ" != "ok" ]; then
  echo "❌ apiserver /healthz is not ok (got '${HZ:-no response}') — etcd/control-plane is unhealthy"; exit 1
fi
if ! kubectl get nodes 2>/dev/null | grep -q ' Ready'; then
  echo "❌ no Ready node reported — control plane is not healthy"; exit 1
fi
echo "✅ control plane healthy after the restore exercise (/healthz=ok, node Ready, restore dir present)"; exit 0
