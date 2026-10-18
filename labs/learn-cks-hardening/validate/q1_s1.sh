#!/bin/bash
M=/etc/kubernetes/manifests/kube-scheduler.yaml
OUT=$(docker exec "$CP" stat -c '%a %U:%G' "$M" 2>/dev/null)
MODE=${OUT%% *}
OWN=${OUT#* }
if [ -z "$OUT" ]; then
  echo "❌ cannot stat $M on $CP (missing?). Expected mode 600 root:root."; exit 1
fi
if [ "$MODE" != "600" ]; then
  echo "❌ $M is mode '${MODE}' on $CP (expected 600). Run: docker exec $CP chmod 600 $M"; exit 1
fi
if [ "$OWN" != "root:root" ]; then
  echo "❌ $M is owned '${OWN}' on $CP (expected root:root). Run: docker exec $CP chown root:root $M"; exit 1
fi
echo "✅ $M is mode 600 root:root on $CP"; exit 0
