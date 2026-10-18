#!/bin/bash
NS=cks-supply
P=digest-pod
kubectl -n "$NS" get pod "$P" >/dev/null 2>&1 || { echo "❌ pod $P not found in $NS. Create it with an image pinned by @sha256: digest."; exit 1; }
IMG=$(kubectl -n "$NS" get pod "$P" -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)
echo "$IMG" | grep -q '@sha256:' || { echo "❌ image '${IMG:-unset}' is not pinned by digest. Use e.g. busybox@sha256:<64-hex-digest> instead of a tag."; exit 1; }
echo "✅ digest-pod image is pinned by @sha256: digest ($IMG)"
exit 0
