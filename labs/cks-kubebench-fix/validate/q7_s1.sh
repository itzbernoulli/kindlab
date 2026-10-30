#!/bin/bash
# Diagnose-and-fix: the kubelet config FILE must be exactly mode 600 on $W1 (CIS 4.1.9).
# Also confirm the file still carries readOnlyPort: 0 so this step can't undo step 5.
C=/var/lib/kubelet/config.yaml
MODE=$(docker exec "$W1" stat -c '%a' "$C" 2>/dev/null)
if [ "$MODE" != "600" ]; then
  echo "❌ $C on $W1 is mode '${MODE:-missing}' (expected exactly 600). Run: docker exec $W1 chmod 600 $C"; exit 1
fi
if ! docker exec "$W1" grep -Eq '^[[:space:]]*readOnlyPort:[[:space:]]*0[[:space:]]*$' "$C" 2>/dev/null; then
  echo "❌ $C is mode 600 but readOnlyPort is no longer 0 — keep the step-5 fix in place (readOnlyPort: 0)."; exit 1
fi
echo "✅ kubelet config on $W1 is mode 600 (readOnlyPort: 0 preserved)"; exit 0
