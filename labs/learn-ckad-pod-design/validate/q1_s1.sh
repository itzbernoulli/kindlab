#!/bin/bash
NS=pod-design
POD=web-sidecar
J=$(kubectl -n "$NS" get pod "$POD" -o json 2>/dev/null)
[ -z "$J" ] && { echo "❌ Pod $POD not found in $NS. Create it with a web (nginx) + writer (busybox) container."; exit 1; }

# both container images present
WEB=$(echo "$J" | jq -r '.spec.containers[]|select(.name=="web")|.image')
WRITER=$(echo "$J" | jq -r '.spec.containers[]|select(.name=="writer")|.image')
echo "$WEB" | grep -q '^nginx' || { echo "❌ container 'web' must use image nginx:1.25 (got '${WEB:-missing}')."; exit 1; }
echo "$WRITER" | grep -q '^busybox' || { echo "❌ sidecar 'writer' must use image busybox:1.36 (got '${WRITER:-missing}')."; exit 1; }

# shared emptyDir volume named 'content'
HASVOL=$(echo "$J" | jq -r '.spec.volumes[]?|select(.name=="content" and (.emptyDir!=null))|.name')
[ "$HASVOL" = "content" ] || { echo "❌ expected an emptyDir volume named 'content'."; exit 1; }

# web mounts content at /usr/share/nginx/html
WMP=$(echo "$J" | jq -r '.spec.containers[]|select(.name=="web")|.volumeMounts[]?|select(.name=="content")|.mountPath')
[ "$WMP" = "/usr/share/nginx/html" ] || { echo "❌ 'web' must mount volume 'content' at /usr/share/nginx/html (got '${WMP:-none}')."; exit 1; }

# writer mounts content at /data
RMP=$(echo "$J" | jq -r '.spec.containers[]|select(.name=="writer")|.volumeMounts[]?|select(.name=="content")|.mountPath')
[ "$RMP" = "/data" ] || { echo "❌ 'writer' must mount the SAME volume 'content' at /data (got '${RMP:-none}')."; exit 1; }

# running and 2/2 ready
PHASE=$(echo "$J" | jq -r '.status.phase')
READY=$(echo "$J" | jq -r '[.status.containerStatuses[]?|select(.ready==true)]|length')
[ "$PHASE" = "Running" ] && [ "$READY" = "2" ] || { echo "❌ Pod not Running with 2/2 ready yet (phase=$PHASE, ready=$READY/2)."; exit 1; }

echo "✅ web-sidecar runs web+writer sharing the 'content' emptyDir (writer at /data)"
exit 0
