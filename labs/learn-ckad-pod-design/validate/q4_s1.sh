#!/bin/bash
NS=pod-design
POD=slow-start
J=$(kubectl -n "$NS" get pod "$POD" -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Pod $POD not found in $NS. Create it with a startupProbe + readinessProbe."; exit 1; }

C='.spec.containers[]|select(.name=="web")'

# startup httpGet present
SPATH=$(echo "$J" | jq -r "$C|.startupProbe.httpGet.path // empty")
SPORT=$(echo "$J" | jq -r "$C|.startupProbe.httpGet.port // empty")
[ -n "$SPATH" ] && [ -n "$SPORT" ] || { echo "❌ container 'web' needs an httpGet startupProbe (path+port)."; exit 1; }

# readiness httpGet present
RPATH=$(echo "$J" | jq -r "$C|.readinessProbe.httpGet.path // empty")
RPORT=$(echo "$J" | jq -r "$C|.readinessProbe.httpGet.port // empty")
[ -n "$RPATH" ] && [ -n "$RPORT" ] || { echo "❌ container 'web' needs an httpGet readinessProbe (path+port)."; exit 1; }

# running and ready
PHASE=$(echo "$J" | jq -r '.status.phase')
READY=$(echo "$J" | jq -r '.status.containerStatuses[]?|select(.name=="web")|.ready')
[ "$PHASE" = "Running" ] && [ "$READY" = "true" ] || { echo "❌ Pod not Running/ready yet (phase=$PHASE, ready=$READY)."; exit 1; }

echo "✅ slow-start has httpGet startup + readiness probes and is 1/1 ready"
exit 0
