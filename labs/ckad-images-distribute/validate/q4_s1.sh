#!/bin/bash
NS=images-learn
PH=$(kubectl -n "$NS" get pod myapp -o jsonpath='{.status.phase}' 2>/dev/null)
IMG=$(kubectl -n "$NS" get pod myapp -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)
if [ -z "$PH" ]; then
  echo "❌ pod 'myapp' not found in $NS — load the image (kind load docker-image myapp:2.0 --name kindlab) then run it with imagePullPolicy IfNotPresent"; exit 1
fi
if [ "$IMG" != "myapp:2.0" ]; then
  echo "❌ pod 'myapp' uses image '$IMG', expected 'myapp:2.0'"; exit 1
fi
if [ "$PH" != "Running" ]; then
  echo "❌ pod 'myapp' is '$PH', not Running. If ErrImagePull/ImagePullBackOff, the node lacks the image — run: kind load docker-image myapp:2.0 --name kindlab (and set imagePullPolicy: IfNotPresent)"; exit 1
fi
echo "✅ pod 'myapp' is Running from the locally-built image myapp:2.0 (loaded into the cluster)"; exit 0
