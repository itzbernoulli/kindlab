#!/bin/bash
# Pass only when the lab's failing drop-in is gone AND $W2 is Ready again.

# 1) the broken drop-in must be removed from the node
if docker exec "$W2" test -f /etc/systemd/system/kubelet.service.d/99-lab-break.conf 2>/dev/null; then
  echo "❌ the failing drop-in /etc/systemd/system/kubelet.service.d/99-lab-break.conf is still on $W2. Remove it, then: systemctl daemon-reload && systemctl restart kubelet."
  exit 1
fi

# 2) the node must report Ready (kubelet healthy and posting status)
READY=$(kubectl get node "$W2" -o jsonpath='{range .status.conditions[?(@.type=="Ready")]}{.status}{end}' 2>/dev/null)
if [ "$READY" = "True" ]; then
  echo "✅ kubelet healthy and $W2 is Ready"
  exit 0
fi

echo "❌ $W2 is not Ready yet (Ready='${READY:-unknown}'). After removing the drop-in run: systemctl daemon-reload && systemctl restart kubelet, then give the node ~30s to report Ready."
exit 1
