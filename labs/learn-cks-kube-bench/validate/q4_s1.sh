#!/bin/bash
# The CA private key must be exactly mode 600 on $CP (keys must not be group/world readable).
K=/etc/kubernetes/pki/ca.key
MODE=$(docker exec "$CP" stat -c '%a' "$K" 2>/dev/null)
if [ "$MODE" = "600" ]; then
  echo "✅ $K is mode 600 on $CP"; exit 0
fi
echo "❌ $K is mode '${MODE:-missing}' on $CP (expected exactly 600). Run: docker exec $CP chmod 600 $K"; exit 1
