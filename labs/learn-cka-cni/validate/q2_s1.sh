#!/bin/bash
# Inspection step: node $W1 must have a podCIDR in 10.244.0.0/16 and its kindnet CNI config present.
CIDR=$(kubectl get node "$W1" -o jsonpath='{.spec.podCIDR}' 2>/dev/null)
if [ -z "$CIDR" ]; then echo "❌ node '$W1' has no .spec.podCIDR"; exit 1; fi
case "$CIDR" in
  10.244.*) : ;;
  *) echo "❌ node '$W1' podCIDR '$CIDR' is not inside the pod CIDR 10.244.0.0/16"; exit 1;;
esac
if ! docker exec "$W1" test -f /etc/cni/net.d/10-kindnet.conflist 2>/dev/null; then
  echo "❌ /etc/cni/net.d/10-kindnet.conflist missing on node '$W1' (the CNI config is absent)"; exit 1
fi
echo "✅ $W1 has podCIDR $CIDR and /etc/cni/net.d/10-kindnet.conflist is present"
exit 0
