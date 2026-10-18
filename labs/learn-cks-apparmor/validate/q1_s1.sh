#!/bin/bash
# Profile file must exist on $W1 and contain a deny-write rule for /etc/secret-data/.
F=/etc/apparmor.d/k8s-deny-write
if ! docker exec "$W1" test -f "$F" 2>/dev/null; then
  echo "❌ no profile file at $F on $W1. Write it and load with apparmor_parser -r."; exit 1
fi
# Must name the profile and deny writes under /etc/secret-data/.
if docker exec "$W1" sh -c "grep -q 'profile k8s-deny-write' $F && grep -Eq 'deny[[:space:]]+/etc/secret-data/.* w' $F" 2>/dev/null; then
  echo "✅ profile k8s-deny-write present on $W1 with deny-write rule for /etc/secret-data/"; exit 0
fi
echo "❌ $F exists but is missing 'profile k8s-deny-write' or a 'deny /etc/secret-data/** w,' rule."; exit 1
