#!/bin/bash
# /opt/snap-fixed.db must be a VALID etcd snapshot (non-zero revision), and must
# NOT be a copy of the seeded bad file /opt/snap-bad.db.
if ! docker exec "$CP" test -f /opt/snap-fixed.db 2>/dev/null; then
  echo "❌ /opt/snap-fixed.db not found on $CP — take a real snapshot from the live etcd and place it there"; exit 1
fi
# Guard against simply copying the bad file.
if docker exec "$CP" test -f /opt/snap-bad.db 2>/dev/null; then
  BAD=$(docker exec "$CP" md5sum /opt/snap-bad.db 2>/dev/null | awk '{print $1}')
  FIX=$(docker exec "$CP" md5sum /opt/snap-fixed.db 2>/dev/null | awk '{print $1}')
  if [ -n "$BAD" ] && [ "$BAD" = "$FIX" ]; then
    echo "❌ /opt/snap-fixed.db is identical to the broken /opt/snap-bad.db — take a FRESH snapshot, don't copy the bad file"; exit 1
  fi
fi
# Validate it with etcdutl (non-zero revision) via the etcd pod on the mounted path.
POD=$(kubectl -n kube-system get pods -l component=etcd -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$POD" ]; then echo "❌ could not find the etcd pod in kube-system"; exit 1; fi
docker exec "$CP" cp /opt/snap-fixed.db /var/lib/etcd/.q7check.db >/dev/null 2>&1
OUT=$(kubectl -n kube-system exec "$POD" -- etcdutl --write-out=json snapshot status /var/lib/etcd/.q7check.db 2>/dev/null)
docker exec "$CP" rm -f /var/lib/etcd/.q7check.db >/dev/null 2>&1
if ! echo "$OUT" | grep -q '"hash"' || ! echo "$OUT" | grep -qE '"revision":[1-9][0-9]*'; then
  echo "❌ /opt/snap-fixed.db does not pass 'etcdutl snapshot status' (no valid hash/revision) — it is not a usable snapshot"; exit 1
fi
REV=$(echo "$OUT" | grep -oE '"revision":[0-9]+' | head -1 | cut -d: -f2)
echo "✅ /opt/snap-fixed.db is a valid snapshot (revision $REV) and differs from the broken file"; exit 0
