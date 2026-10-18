#!/bin/bash
K=/etc/kubernetes/pki/ca.key
MODE=$(docker exec "$CP" stat -c '%a' "$K" 2>/dev/null)
if [ "$MODE" = "600" ]; then
  echo "✅ $K is mode 600 on $CP"; exit 0
fi
echo "❌ $K is mode '${MODE:-missing}' on $CP (expected 600). Run: docker exec $CP chmod 600 $K"; exit 1
