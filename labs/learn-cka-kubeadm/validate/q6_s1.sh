#!/bin/bash
# Step 6: apiserver.crt must be renewed — serial differs from the recorded original
# AND NotAfter is >300 days out (openssl checkend seconds).
CRT=/etc/kubernetes/pki/apiserver.crt
docker exec "$CP" test -f "$CRT" 2>/dev/null || { echo "❌ $CRT not found on \$CP"; exit 1; }
ORIG=$(docker exec "$CP" cat /tmp/apiserver.orig.serial 2>/dev/null | tr -d '[:space:]')
[ -z "$ORIG" ] && { echo "❌ original serial not recorded — re-Start the lesson"; exit 1; }
CUR=$(docker exec "$CP" openssl x509 -in "$CRT" -noout -serial 2>/dev/null | tr -d '[:space:]')
if [ -z "$CUR" ] || [ "$CUR" = "$ORIG" ]; then
  echo "❌ apiserver cert not renewed yet (serial unchanged). Run: docker exec \"\$CP\" kubeadm certs renew apiserver"; exit 1
fi
# NotAfter must be >300 days out: checkend returns 0 if cert is NOT expiring within N seconds.
if docker exec "$CP" openssl x509 -in "$CRT" -noout -checkend 25920000 >/dev/null 2>&1; then
  END=$(docker exec "$CP" openssl x509 -in "$CRT" -noout -enddate 2>/dev/null | cut -d= -f2)
  echo "✅ apiserver cert renewed (new serial; valid >300 days, NotAfter ${END:-~1y})"; exit 0
fi
echo "❌ apiserver cert serial changed but NotAfter is NOT >300 days out — did the renew succeed? Run: docker exec \"\$CP\" kubeadm certs renew apiserver"; exit 1
