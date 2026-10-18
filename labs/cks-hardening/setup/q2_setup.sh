#!/bin/bash
# Ensure the kubelet read-only port is ENABLED on $W1 so the candidate must disable it.
# We seed readOnlyPort: 10255 if it is currently 0 or absent, then restart the kubelet.
# Breaking only a worker kubelet config (recoverable) — never the apiserver/etcd.
C=/var/lib/kubelet/config.yaml
docker exec "$W1" sh -c "
  if grep -q '^readOnlyPort:' $C; then
    sed -i 's/^readOnlyPort:.*/readOnlyPort: 10255/' $C
  else
    echo 'readOnlyPort: 10255' >> $C
  fi
  systemctl restart kubelet
"
echo "seeded readOnlyPort: 10255 on $W1 (candidate must set it to 0 and restart kubelet)"
