#!/bin/bash
# Idempotent reset for learn-cka-etcd-restore.
# Node-level lab: cleans scratch artifacts on $CP WITHOUT touching the live etcd
# data dir (/var/lib/etcd/member) or the live static-pod manifest. Safe to re-run.

# Clear prior snapshot files, recorded answers, and restored data dirs on $CP.
docker exec "$CP" rm -f  /var/lib/etcd/snap.db /var/lib/etcd/snap-fixed.db \
  /var/lib/etcd/.q1check.db /var/lib/etcd/.q7check.db /var/lib/etcd/.bad.db \
  /opt/snap.db /opt/snap-fixed.db /opt/snap-bad.db \
  /opt/etcd-datadir.txt /opt/etcd-endpoint.txt >/dev/null 2>&1
docker exec "$CP" rm -rf /var/lib/etcd/etcd-restore /var/lib/etcd/etcd-restore2 \
  /var/lib/etcd/restore >/dev/null 2>&1

# Seed a BROKEN "backup" for the step-7 diagnose-and-fix: a file that exists and
# is non-trivial in size but is NOT a valid etcd snapshot (garbage bytes).
docker exec "$CP" sh -c 'head -c 200000 /dev/urandom > /opt/snap-bad.db' >/dev/null 2>&1

# Sanity: the live cluster must still be healthy before the learner starts.
kubectl get --raw=/healthz >/dev/null 2>&1

echo "learn-cka-etcd-restore reset on $CP: scratch artifacts cleared, broken /opt/snap-bad.db seeded (live etcd untouched)"
