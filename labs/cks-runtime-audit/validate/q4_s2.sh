#!/bin/bash
# The audit log file must exist on the node (apiserver writes it once audit logging is active).
F=/var/log/kubernetes/audit.log
if docker exec "$CP" test -f "$F" 2>/dev/null; then
  SZ=$(docker exec "$CP" sh -c "stat -c%s $F 2>/dev/null || echo 0")
  echo "✅ audit log exists at $F on $CP (${SZ} bytes)"; exit 0
fi
echo "❌ no audit log at $F on $CP — ensure --audit-log-path points there, /var/log/kubernetes is mounted into the apiserver (hostPath), and the apiserver restarted"; exit 1
