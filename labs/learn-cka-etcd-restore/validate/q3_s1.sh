#!/bin/bash
# The restored data dir must exist on $CP and contain a member/ subdirectory,
# while the live /var/lib/etcd/member must remain intact.
if ! docker exec "$CP" test -d /var/lib/etcd/etcd-restore 2>/dev/null; then
  echo "❌ /var/lib/etcd/etcd-restore not found on $CP — run: etcdutl snapshot restore /var/lib/etcd/snap.db --data-dir /var/lib/etcd/etcd-restore (via the etcd pod)"; exit 1
fi
if ! docker exec "$CP" test -d /var/lib/etcd/etcd-restore/member 2>/dev/null; then
  echo "❌ /var/lib/etcd/etcd-restore exists but has no member/ subdirectory — the restore did not complete"; exit 1
fi
# A real restore produces snap/ and wal/ under member/.
if ! docker exec "$CP" test -d /var/lib/etcd/etcd-restore/member/snap 2>/dev/null; then
  echo "❌ /var/lib/etcd/etcd-restore/member has no snap/ — re-run the restore from the snapshot"; exit 1
fi
# The live etcd data dir must be untouched.
if ! docker exec "$CP" test -d /var/lib/etcd/member 2>/dev/null; then
  echo "❌ the live /var/lib/etcd/member is missing — the restore must NOT touch the live data dir"; exit 1
fi
echo "✅ snapshot restored into /var/lib/etcd/etcd-restore (member/ present); live data dir intact"; exit 0
