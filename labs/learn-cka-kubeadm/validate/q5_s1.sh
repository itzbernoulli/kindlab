#!/bin/bash
V=$(docker exec "$CP" cat /tmp/serverversion.txt 2>/dev/null | tr -d '[:space:]')
if echo "$V" | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+'; then
  echo "✅ server version captured on $CP: $V"; exit 0
fi
echo "❌ /tmp/serverversion.txt on $CP does not contain a v<major>.<minor>.<patch> version (got: '${V:-empty}'). Run kubeadm upgrade plan, then capture kubectl version into the file."; exit 1
