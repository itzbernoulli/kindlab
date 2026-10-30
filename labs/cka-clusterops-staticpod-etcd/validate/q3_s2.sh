#!/bin/bash
# A real etcd snapshot is a bbolt DB — far larger than 1KB and binary, not text.
SZ=$(docker exec "$CP" sh -c 'stat -c%s /opt/snapshot.db 2>/dev/null || echo 0')
if ! [ "${SZ:-0}" -gt 1024 ] 2>/dev/null; then
  echo "❌ snapshot missing or too small (${SZ:-0} bytes). Use 'etcdctl snapshot save' from the etcd pod — don't create an empty/placeholder file."; exit 1
fi
# Reject an obvious text fake: a genuine snapshot has NUL bytes within its first block.
if docker exec "$CP" sh -c 'head -c 2048 /opt/snapshot.db | LC_ALL=C grep -q "$(printf "\000")"' 2>/dev/null; then
  echo "✅ snapshot is ${SZ} bytes and binary (valid etcd backup)"; exit 0
fi
echo "❌ /opt/snapshot.db is ${SZ} bytes but looks like text, not an etcd snapshot. Produce it with 'etcdctl snapshot save'."; exit 1
