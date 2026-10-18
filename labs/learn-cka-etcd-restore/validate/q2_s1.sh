#!/bin/bash
# etcdutl snapshot status must succeed against the saved snapshot and report a hash + revision.
if ! docker exec "$CP" test -f /var/lib/etcd/snap.db 2>/dev/null; then
  echo "❌ /var/lib/etcd/snap.db not found on $CP — complete step 1 first (snapshot save)"; exit 1
fi
POD=$(kubectl -n kube-system get pods -l component=etcd -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$POD" ]; then echo "❌ could not find the etcd pod in kube-system"; exit 1; fi
OUT=$(kubectl -n kube-system exec "$POD" -- etcdutl --write-out=json snapshot status /var/lib/etcd/snap.db 2>/dev/null)
if [ -z "$OUT" ]; then
  echo "❌ 'etcdutl snapshot status /var/lib/etcd/snap.db' produced no output — run it via the etcd pod"; exit 1
fi
# JSON reports hash and revision; require a non-zero revision and a hash field.
if echo "$OUT" | grep -q '"hash"' && echo "$OUT" | grep -qE '"revision":[1-9][0-9]*'; then
  REV=$(echo "$OUT" | grep -oE '"revision":[0-9]+' | head -1 | cut -d: -f2)
  echo "✅ snapshot status OK — reports a hash and revision ($REV)"; exit 0
fi
echo "❌ snapshot status did not report a valid hash/revision — snapshot may be corrupt"; exit 1
