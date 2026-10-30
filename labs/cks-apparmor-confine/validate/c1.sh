#!/bin/bash
# Profile file must exist on $W1 with profile name k8s-deny-write + a deny-write rule for /etc/secret-data/.
F=/etc/apparmor.d/k8s-deny-write
if ! docker exec "$W1" test -f "$F" 2>/dev/null; then
  echo "❌ no profile file at $F on $W1. Write it and load with 'apparmor_parser -r'."; exit 1
fi
if ! docker exec "$W1" grep -q 'profile k8s-deny-write' "$F" 2>/dev/null; then
  echo "❌ $F exists but has no 'profile k8s-deny-write' declaration (the profile NAME must match the filename)."; exit 1
fi
if ! docker exec "$W1" grep -Eq 'deny[[:space:]]+/etc/secret-data/.*[[:space:]]+w' "$F" 2>/dev/null; then
  echo "❌ $F has no 'deny /etc/secret-data/** w,' rule — writes under /etc/secret-data/ are not denied."; exit 1
fi
echo "✅ $F on $W1 declares profile k8s-deny-write and denies writes to /etc/secret-data/"; exit 0
