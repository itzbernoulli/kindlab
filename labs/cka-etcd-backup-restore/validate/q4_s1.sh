#!/bin/bash
# The identity-flagged restore must produce /var/lib/etcd/etcd-restore2 with a
# proper member tree (member/snap + member/wal), distinct from the step-3 dir,
# with the live data dir untouched.
if ! docker exec "$CP" test -d /var/lib/etcd/etcd-restore2 2>/dev/null; then
  echo "❌ /var/lib/etcd/etcd-restore2 not found on $CP — restore again with --name/--initial-cluster/--initial-advertise-peer-urls into --data-dir /var/lib/etcd/etcd-restore2"; exit 1
fi
if ! docker exec "$CP" test -d /var/lib/etcd/etcd-restore2/member/snap 2>/dev/null; then
  echo "❌ /var/lib/etcd/etcd-restore2 has no member/snap — the identity restore did not complete; check the flag values"; exit 1
fi
if ! docker exec "$CP" test -d /var/lib/etcd/etcd-restore2/member/wal 2>/dev/null; then
  echo "❌ /var/lib/etcd/etcd-restore2 has no member/wal — the identity restore did not complete; check the flag values"; exit 1
fi
# Must be a second restore, not a rename of the step-3 dir.
if ! docker exec "$CP" test -d /var/lib/etcd/etcd-restore/member 2>/dev/null; then
  echo "❌ the step-3 restore dir /var/lib/etcd/etcd-restore is gone — do a SECOND restore into etcd-restore2, keep the first"; exit 1
fi
if ! docker exec "$CP" test -d /var/lib/etcd/member 2>/dev/null; then
  echo "❌ the live /var/lib/etcd/member is missing — the restore must NOT touch the live data dir"; exit 1
fi
echo "✅ identity restore produced /var/lib/etcd/etcd-restore2 (member/snap + member/wal); step-3 dir and live data intact"; exit 0
