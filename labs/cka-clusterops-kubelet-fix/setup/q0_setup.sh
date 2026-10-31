#!/bin/bash
# Reset cka-clusterops-kubelet-fix to a clean slate.
# NODE-LEVEL lab: cleanup is resource/node-level — never delete a namespace.
# Remove the lab's failing kubelet drop-in on $W2 (if any) and bring kubelet back,
# so the node is Ready before the fault is (re)injected.
docker exec "$W2" bash -c '
  rm -f /etc/systemd/system/kubelet.service.d/99-lab-break.conf
  systemctl daemon-reload
  systemctl restart kubelet
' >/dev/null 2>&1

echo "cka-clusterops-kubelet-fix reset: $W2 kubelet drop-in cleared, kubelet restarted"
