#!/bin/bash
# Credit "node healthy after the change" only once the change is actually present,
# so an untouched cluster (node trivially Ready) earns nothing.
C=/var/lib/kubelet/config.yaml
if ! docker exec "$W1" grep -Eq '^[[:space:]]*readOnlyPort:[[:space:]]*0[[:space:]]*$' "$C" 2>/dev/null; then
  echo "❌ readOnlyPort:0 not set on $W1 yet — set it and restart the kubelet (node must stay Ready)."; exit 1
fi
for i in $(seq 1 12); do
  ST=$(kubectl get node "$W1" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
  [ "$ST" = "True" ] && { echo "✅ readOnlyPort:0 applied and node $W1 is Ready"; exit 0; }
  sleep 5
done
echo "❌ node $W1 not Ready after kubelet restart (Ready='${ST:-unknown}'). Check: docker exec $W1 systemctl status kubelet"; exit 1
