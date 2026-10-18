#!/bin/bash
# A valid, non-trivial etcd snapshot must exist at /opt/snap.db on $CP.
if ! docker exec "$CP" test -f /opt/snap.db 2>/dev/null; then
  echo "❌ /opt/snap.db not found on $CP — save a snapshot to /var/lib/etcd/snap.db from the etcd pod, then: docker exec \"\$CP\" cp /var/lib/etcd/snap.db /opt/snap.db"; exit 1
fi
SIZE=$(docker exec "$CP" stat -c %s /opt/snap.db 2>/dev/null)
if [ -z "$SIZE" ] || [ "$SIZE" -lt 102400 ]; then
  echo "❌ /opt/snap.db is too small (${SIZE:-0} bytes) to be a real etcd snapshot — re-run 'etcdctl snapshot save'"; exit 1
fi
# Confirm it is a VALID etcd snapshot (readable by etcdutl with a non-zero revision) to rule out a dummy file.
POD=$(kubectl -n kube-system get pods -l component=etcd -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$POD" ]; then echo "❌ could not find the etcd pod in kube-system"; exit 1; fi
docker exec "$CP" cp /opt/snap.db /var/lib/etcd/.q1check.db >/dev/null 2>&1
OUT=$(kubectl -n kube-system exec "$POD" -- etcdutl --write-out=json snapshot status /var/lib/etcd/.q1check.db 2>/dev/null)
docker exec "$CP" rm -f /var/lib/etcd/.q1check.db >/dev/null 2>&1
if ! echo "$OUT" | grep -q '"hash"' || ! echo "$OUT" | grep -qE '"revision":[1-9][0-9]*'; then
  echo "❌ /opt/snap.db is not a valid etcd snapshot — use 'etcdctl snapshot save' against the live etcd (TLS flags + :2379)"; exit 1
fi
echo "✅ valid etcd snapshot present at /opt/snap.db on $CP ($SIZE bytes, non-zero revision)"; exit 0
