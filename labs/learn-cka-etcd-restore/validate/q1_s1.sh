#!/bin/bash
# A non-trivial snapshot file must exist at /opt/snap.db on $CP.
if ! docker exec "$CP" test -f /opt/snap.db 2>/dev/null; then
  echo "❌ /opt/snap.db not found on $CP — save a snapshot to /var/lib/etcd/snap.db from the etcd pod, then: docker exec \"\$CP\" cp /var/lib/etcd/snap.db /opt/snap.db"; exit 1
fi
SIZE=$(docker exec "$CP" stat -c %s /opt/snap.db 2>/dev/null)
if [ -z "$SIZE" ] || [ "$SIZE" -lt 102400 ]; then
  echo "❌ /opt/snap.db is too small (${SIZE:-0} bytes) to be a real etcd snapshot — re-run etcdctl snapshot save"; exit 1
fi
# Confirm it is a valid etcd snapshot (readable by etcdutl) to rule out a dummy file.
POD=$(kubectl -n kube-system get pods -l component=etcd -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
docker exec "$CP" cp /opt/snap.db /var/lib/etcd/.q1check.db >/dev/null 2>&1
OK=$(kubectl -n kube-system exec "$POD" -- etcdutl snapshot status /var/lib/etcd/.q1check.db 2>/dev/null)
docker exec "$CP" rm -f /var/lib/etcd/.q1check.db >/dev/null 2>&1
if [ -z "$OK" ]; then
  echo "❌ /opt/snap.db is not a valid etcd snapshot — use 'etcdctl snapshot save' against the live etcd"; exit 1
fi
echo "✅ valid etcd snapshot present at /opt/snap.db on $CP ($SIZE bytes)"; exit 0
