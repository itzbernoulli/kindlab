#!/bin/bash
# Idempotent reset for learn-cka-etcd-restore.
# Removes any artifacts from a prior run WITHOUT touching the live etcd data
# (/var/lib/etcd/member) or the live static-pod manifest. Safe to re-run.

# Clean prior snapshot files and restored data dirs on the control-plane node.
docker exec "$CP" rm -f  /var/lib/etcd/snap.db /opt/snap.db /opt/etcd-datadir.txt >/dev/null 2>&1
docker exec "$CP" rm -rf /var/lib/etcd/etcd-restore /var/lib/etcd/restore     >/dev/null 2>&1

# Sanity: the live cluster must still be healthy before the learner starts.
kubectl get --raw=/healthz >/dev/null 2>&1

echo "learn-cka-etcd-restore reset: prior snapshot/restore artifacts cleared on $CP (live etcd untouched)"
