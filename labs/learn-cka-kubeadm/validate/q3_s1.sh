#!/bin/bash
# Step 3: /tmp/apiserver-image.txt on $CP must equal the ACTUAL image: from
# /etc/kubernetes/manifests/kube-apiserver.yaml, and look like kube-apiserver:v<x.y.z>.
TRUTH=$(docker exec "$CP" sh -c "grep -E '^\s*image:' /etc/kubernetes/manifests/kube-apiserver.yaml | head -1 | awk '{print \$2}'" 2>/dev/null | tr -d '[:space:]')
if [ -z "$TRUTH" ]; then
  echo "❌ could not read image: from /etc/kubernetes/manifests/kube-apiserver.yaml on \$CP (unexpected cluster state)"; exit 1
fi
GOT=$(docker exec "$CP" cat /tmp/apiserver-image.txt 2>/dev/null | tr -d '[:space:]')
if [ -z "$GOT" ]; then
  echo "❌ /tmp/apiserver-image.txt not found/empty on \$CP. Write the apiserver 'image:' value from the static manifest"; exit 1
fi
if ! echo "$GOT" | grep -qE 'kube-apiserver:v[0-9]+\.[0-9]+\.[0-9]+'; then
  echo "❌ /tmp/apiserver-image.txt ('$GOT') is not a kube-apiserver:v<major>.<minor>.<patch> image reference"; exit 1
fi
if [ "$GOT" = "$TRUTH" ]; then
  echo "✅ /tmp/apiserver-image.txt = '$GOT' matches the static manifest image"; exit 0
fi
echo "❌ /tmp/apiserver-image.txt is '$GOT' but the manifest image is '$TRUTH' — write the exact image: value"; exit 1
