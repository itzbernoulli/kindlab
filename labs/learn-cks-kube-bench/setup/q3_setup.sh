#!/bin/bash
# Enable the kubelet read-only port on $W1 so the learner must disable it.
# Seed readOnlyPort: 10255 (replace if present, append if absent), then restart kubelet.
# Breaking only a worker kubelet config is recoverable — never the apiserver/etcd.
C=/var/lib/kubelet/config.yaml
docker exec "$W1" sh -c "
  if grep -q '^readOnlyPort:' $C; then
    sed -i 's/^readOnlyPort:.*/readOnlyPort: 10255/' $C
  else
    echo 'readOnlyPort: 10255' >> $C
  fi
  systemctl restart kubelet
"
echo "seeded readOnlyPort: 10255 on $W1 (set it to 0 and restart kubelet)"
