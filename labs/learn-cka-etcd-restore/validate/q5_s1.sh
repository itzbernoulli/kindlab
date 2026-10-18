#!/bin/bash
# /opt/etcd-datadir.txt on $CP must hold the etcd-data hostPath, and the live
# manifest must still point its etcd-data volume at /var/lib/etcd (unchanged).
if ! docker exec "$CP" test -f /opt/etcd-datadir.txt 2>/dev/null; then
  echo "❌ /opt/etcd-datadir.txt not found on $CP — locate the etcd-data hostPath in /etc/kubernetes/manifests/etcd.yaml and write it there"; exit 1
fi
RECORDED=$(docker exec "$CP" cat /opt/etcd-datadir.txt 2>/dev/null | tr -d '[:space:]')
if [ "$RECORDED" != "/var/lib/etcd" ]; then
  echo "❌ /opt/etcd-datadir.txt should contain the etcd-data hostPath '/var/lib/etcd' (got '${RECORDED:-empty}')"; exit 1
fi
# The live manifest must be unchanged: etcd-data volume still maps /var/lib/etcd.
MANIFEST=$(docker exec "$CP" cat /etc/kubernetes/manifests/etcd.yaml 2>/dev/null)
if ! echo "$MANIFEST" | grep -q 'name: etcd-data'; then
  echo "❌ the etcd-data volume is missing from /etc/kubernetes/manifests/etcd.yaml — do NOT modify the live manifest"; exit 1
fi
if ! echo "$MANIFEST" | grep -A2 'hostPath:' | grep -q 'path: /var/lib/etcd'; then
  echo "❌ the live etcd-data hostPath no longer points at /var/lib/etcd — the manifest must stay unchanged in this step"; exit 1
fi
echo "✅ etcd-data hostPath located (/var/lib/etcd) and recorded; live manifest unchanged"; exit 0
