#!/bin/bash
NS=pod-design
POD=init-prep
J=$(kubectl -n "$NS" get pod "$POD" -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Pod $POD not found in $NS. Create it with an init container 'setup' and main container 'app'."; exit 1; }

# init container 'setup' exists using busybox
SETUP=$(echo "$J" | jq -r '.spec.initContainers[]?|select(.name=="setup")|.image')
echo "$SETUP" | grep -q '^busybox' || { echo "❌ expected an init container 'setup' using busybox:1.36 (got '${SETUP:-missing}')."; exit 1; }

# shared emptyDir volume
HASVOL=$(echo "$J" | jq -r '.spec.volumes[]?|select(.name=="shared" and (.emptyDir!=null))|.name')
[ "$HASVOL" = "shared" ] || { echo "❌ expected an emptyDir volume named 'shared'."; exit 1; }

# init mounts shared at /work
IMP=$(echo "$J" | jq -r '.spec.initContainers[]|select(.name=="setup")|.volumeMounts[]?|select(.name=="shared")|.mountPath')
[ "$IMP" = "/work" ] || { echo "❌ init 'setup' must mount 'shared' at /work (got '${IMP:-none}')."; exit 1; }

# app mounts shared at /work
AMP=$(echo "$J" | jq -r '.spec.containers[]|select(.name=="app")|.volumeMounts[]?|select(.name=="shared")|.mountPath')
[ "$AMP" = "/work" ] || { echo "❌ container 'app' must mount 'shared' at /work (got '${AMP:-none}')."; exit 1; }

# init container completed (terminated with exit 0)
ICODE=$(echo "$J" | jq -r '.status.initContainerStatuses[]?|select(.name=="setup")|.state.terminated.exitCode // empty')
[ "$ICODE" = "0" ] || { echo "❌ init container 'setup' has not completed successfully yet (exitCode='${ICODE:-pending}')."; exit 1; }

# pod running
PHASE=$(echo "$J" | jq -r '.status.phase')
[ "$PHASE" = "Running" ] || { echo "❌ Pod not Running yet (phase=$PHASE)."; exit 1; }

echo "✅ init-prep ran init container 'setup' to prepare /work in the shared volume before 'app' started"
exit 0
