#!/bin/bash
# Profile JSON must exist on the worker at the kubelet seccomp localhost path.
P=/var/lib/kubelet/seccomp/profiles/audit.json
if docker exec "$W1" test -f "$P" 2>/dev/null && docker exec "$W1" sh -c "grep -q defaultAction $P" 2>/dev/null; then
  echo "✅ seccomp profile present at $P on $W1"; exit 0
fi
echo "❌ no valid seccomp JSON at $P on $W1 (expected a profile with a 'defaultAction', e.g. SCMP_ACT_LOG)"; exit 1
