#!/bin/bash
# /opt/etcd-endpoint.txt must hold an https client URL on port 2379, and that URL
# must actually appear as a client URL in the live manifest (unchanged).
if ! docker exec "$CP" test -f /opt/etcd-endpoint.txt 2>/dev/null; then
  echo "❌ /opt/etcd-endpoint.txt not found on $CP — read the --advertise-client-urls value from /etc/kubernetes/manifests/etcd.yaml and write it there"; exit 1
fi
RECORDED=$(docker exec "$CP" cat /opt/etcd-endpoint.txt 2>/dev/null | tr -d '[:space:]')
if ! echo "$RECORDED" | grep -qE '^https://[0-9A-Za-z.:-]+:2379$'; then
  echo "❌ /opt/etcd-endpoint.txt must be an https client URL on port 2379 (got '${RECORDED:-empty}') — 2380 is the PEER port, not the client port"; exit 1
fi
# The recorded URL must match a client URL in the live manifest.
MANIFEST=$(docker exec "$CP" cat /etc/kubernetes/manifests/etcd.yaml 2>/dev/null)
if ! echo "$MANIFEST" | grep -E 'client-urls' | grep -qF "$RECORDED"; then
  echo "❌ '$RECORDED' is not an advertise/listen client URL in the manifest — use the exact --advertise-client-urls value from etcd.yaml"; exit 1
fi
echo "✅ etcd client endpoint recorded ($RECORDED) and matches the manifest"; exit 0
