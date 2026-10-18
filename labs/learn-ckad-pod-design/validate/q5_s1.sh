#!/bin/bash
NS=pod-design
POD=graceful
J=$(kubectl -n "$NS" get pod "$POD" -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Pod $POD not found in $NS. Create it with lifecycle hooks + terminationGracePeriodSeconds."; exit 1; }

# grace period 30
GP=$(echo "$J" | jq -r '.spec.terminationGracePeriodSeconds // empty')
[ "$GP" = "30" ] || { echo "❌ terminationGracePeriodSeconds must be 30 (got '${GP:-unset}')."; exit 1; }

C='.spec.containers[]|select(.name=="web")'

# postStart exec hook present
PS=$(echo "$J" | jq -r "$C|.lifecycle.postStart.exec.command // empty | if type==\"array\" then join(\" \") else . end")
[ -n "$PS" ] || { echo "❌ container 'web' needs a postStart exec lifecycle hook."; exit 1; }

# preStop exec hook present
PRE=$(echo "$J" | jq -r "$C|.lifecycle.preStop.exec.command // empty | if type==\"array\" then join(\" \") else . end")
[ -n "$PRE" ] || { echo "❌ container 'web' needs a preStop exec lifecycle hook."; exit 1; }

# running
PHASE=$(echo "$J" | jq -r '.status.phase')
[ "$PHASE" = "Running" ] || { echo "❌ Pod not Running yet (phase=$PHASE)."; exit 1; }

echo "✅ graceful has postStart+preStop exec hooks and terminationGracePeriodSeconds=30"
exit 0
