#!/bin/bash
# Second profile file on $W1: profile name k8s-deny-net + a 'deny network' rule.
# k8s-deny-write must still exist (loading a new profile must not un-load the first).
F=/etc/apparmor.d/k8s-deny-net
if ! docker exec "$W1" test -f "$F" 2>/dev/null; then
  echo "❌ no profile file at $F on $W1. Write it and load with 'apparmor_parser -r'."; exit 1
fi
if ! docker exec "$W1" grep -q 'profile k8s-deny-net' "$F" 2>/dev/null; then
  echo "❌ $F has no 'profile k8s-deny-net' declaration (profile name must match the filename)."; exit 1
fi
if ! docker exec "$W1" grep -Eq 'deny[[:space:]]+network' "$F" 2>/dev/null; then
  echo "❌ $F has no 'deny network,' rule — network access is not denied."; exit 1
fi
if ! docker exec "$W1" test -f /etc/apparmor.d/k8s-deny-write 2>/dev/null; then
  echo "❌ /etc/apparmor.d/k8s-deny-write is gone — loading k8s-deny-net must not remove the Step 1 profile."; exit 1
fi
echo "✅ $F on $W1 declares profile k8s-deny-net with a deny-network rule (k8s-deny-write intact)"; exit 0
