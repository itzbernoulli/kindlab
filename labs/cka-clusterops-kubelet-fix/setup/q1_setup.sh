#!/bin/bash
# Break the kubelet on $W2 with a systemd drop-in whose ExecStartPre always
# fails (/bin/false exits 1), so the unit never starts and $W2 goes NotReady.
# This is version-independent (pure systemd) and fully reversible: the learner
# removes the drop-in, runs daemon-reload, and restarts kubelet.
docker exec "$W2" bash -c '
  mkdir -p /etc/systemd/system/kubelet.service.d
  printf "[Service]\nExecStartPre=/bin/false\n" > /etc/systemd/system/kubelet.service.d/99-lab-break.conf
  systemctl daemon-reload
  systemctl restart kubelet
' >/dev/null 2>&1

echo "kubelet broken on $W2 (failing drop-in 99-lab-break.conf installed) — diagnose & fix it"
