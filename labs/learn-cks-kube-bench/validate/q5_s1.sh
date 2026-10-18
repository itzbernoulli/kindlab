#!/bin/bash
# Match 'readOnlyPort: 0' allowing surrounding whitespace; reject any non-zero value.
C=/var/lib/kubelet/config.yaml
if docker exec "$W1" grep -Eq '^[[:space:]]*readOnlyPort:[[:space:]]*0[[:space:]]*$' "$C" 2>/dev/null; then
  echo "✅ kubelet config on $W1 has readOnlyPort: 0"; exit 0
fi
CUR=$(docker exec "$W1" grep -E '^[[:space:]]*readOnlyPort:' "$C" 2>/dev/null | tr -d '\n')
echo "❌ $C on $W1 does not have 'readOnlyPort: 0' (found: '${CUR:-absent}'). Set readOnlyPort: 0 and restart kubelet."; exit 1
