#!/bin/bash
# Step 2: /tmp/cgroupdriver.txt on $CP must equal the ACTUAL cgroupDriver value from
# /var/lib/kubelet/config.yaml (read from the node as ground truth). Strict match.
TRUTH=$(docker exec "$CP" sh -c "grep -E '^cgroupDriver:' /var/lib/kubelet/config.yaml | awk '{print \$2}'" 2>/dev/null | tr -d '[:space:]')
if [ -z "$TRUTH" ]; then
  echo "❌ could not read cgroupDriver from /var/lib/kubelet/config.yaml on \$CP (unexpected cluster state)"; exit 1
fi
GOT=$(docker exec "$CP" cat /tmp/cgroupdriver.txt 2>/dev/null | tr -d '[:space:]')
if [ -z "$GOT" ]; then
  echo "❌ /tmp/cgroupdriver.txt not found/empty on \$CP. Write ONLY the value, e.g. via grep cgroupDriver ... | awk '{print \$2}'"; exit 1
fi
if [ "$GOT" = "$TRUTH" ]; then
  echo "✅ /tmp/cgroupdriver.txt = '$GOT' matches the kubelet config cgroupDriver"; exit 0
fi
echo "❌ /tmp/cgroupdriver.txt is '$GOT' but the kubelet config cgroupDriver is '$TRUTH' — write ONLY the value, no key/quotes"; exit 1
