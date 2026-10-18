#!/bin/bash
# Step 1: /tmp/versions.txt on $CP must hold a kubeadm version line AND a kubelet line.
OUT=$(docker exec "$CP" cat /tmp/versions.txt 2>/dev/null)
if [ -z "$OUT" ]; then
  echo "❌ /tmp/versions.txt not found on \$CP. Redirect INSIDE the node: docker exec \"\$CP\" sh -c 'kubeadm version -o short > /tmp/versions.txt; kubelet --version >> /tmp/versions.txt'"; exit 1
fi
HAS_KUBEADM=$(echo "$OUT" | grep -ciE 'kubeadm|^v[0-9]+\.[0-9]+\.[0-9]+')
HAS_KUBELET=$(echo "$OUT" | grep -ci 'Kubernetes v[0-9]')
if [ "$HAS_KUBEADM" -ge 1 ] && [ "$HAS_KUBELET" -ge 1 ]; then
  echo "✅ /tmp/versions.txt has a kubeadm version line + a kubelet 'Kubernetes v...' line"; exit 0
fi
echo "❌ /tmp/versions.txt is missing the kubeadm version line and/or the kubelet 'Kubernetes v...' line (content: $(echo "$OUT" | tr '\n' '|'))"; exit 1
