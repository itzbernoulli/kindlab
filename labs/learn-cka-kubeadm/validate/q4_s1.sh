#!/bin/bash
CRT=/etc/kubernetes/pki/apiserver.crt
docker exec "$CP" test -f "$CRT" 2>/dev/null || { echo "❌ $CRT not found on $CP"; exit 1; }
ORIG=$(docker exec "$CP" cat /tmp/apiserver.orig.serial 2>/dev/null)
CUR=$(docker exec "$CP" openssl x509 -in "$CRT" -noout -serial 2>/dev/null)
[ -z "$ORIG" ] && { echo "❌ original serial not recorded — re-Start the lesson"; exit 1; }
if [ -n "$CUR" ] && [ "$CUR" != "$ORIG" ]; then
  END=$(docker exec "$CP" openssl x509 -in "$CRT" -noout -enddate 2>/dev/null)
  echo "✅ apiserver cert renewed (new serial; ${END:-~1y})"; exit 0
fi
echo "❌ apiserver cert not renewed yet (serial unchanged). Run: docker exec \"\$CP\" kubeadm certs renew apiserver"; exit 1
