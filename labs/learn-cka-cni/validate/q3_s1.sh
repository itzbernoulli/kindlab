#!/bin/bash
# After the fix: the CNI config is back on $W2 and the pinned pod 'netbroken' has an IP.
if ! kubectl get pod netbroken -n cni-learn >/dev/null 2>&1; then
  echo "❌ pod 'netbroken' not found — don't delete it; fix the node's CNI so it gets an IP"; exit 1
fi
NODE=$(kubectl get pod netbroken -n cni-learn -o jsonpath='{.spec.nodeName}' 2>/dev/null)
if [ "$NODE" != "$W2" ]; then echo "❌ netbroken must stay pinned to $W2 (on '${NODE:-none}') — fix the CNI, don't reschedule it"; exit 1; fi
if ! docker exec "$W2" test -f /etc/cni/net.d/10-kindnet.conflist 2>/dev/null; then
  echo "❌ /etc/cni/net.d/10-kindnet.conflist still missing on $W2 — restart kindnet on that node to rewrite it"; exit 1
fi
IP=$(kubectl get pod netbroken -n cni-learn -o jsonpath='{.status.podIP}' 2>/dev/null)
if [ -z "$IP" ]; then echo "❌ netbroken still has no IP — give kindnet ~15s after restarting it on $W2"; exit 1; fi
case "$IP" in
  10.244.*) echo "✅ CNI restored on $W2 — netbroken now has IP $IP"; exit 0;;
  *) echo "❌ netbroken IP '$IP' is not in the pod CIDR 10.244.0.0/16"; exit 1;;
esac
