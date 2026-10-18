#!/bin/bash
PH=$(kubectl -n storage-learn get pod app -o jsonpath='{.status.phase}' 2>/dev/null)
CLAIM=$(kubectl -n storage-learn get pod app -o jsonpath='{.spec.volumes[?(@.persistentVolumeClaim)].persistentVolumeClaim.claimName}' 2>/dev/null)
MP=$(kubectl -n storage-learn get pod app -o jsonpath='{.spec.containers[0].volumeMounts[?(@.mountPath=="/data")].mountPath}' 2>/dev/null)
if [ -z "$PH" ]; then
  echo "❌ Pod 'app' not found in namespace storage-learn."; exit 1
fi
if [ "$CLAIM" != "pvc-data" ]; then
  echo "❌ Pod app does not mount PVC pvc-data (claimName='${CLAIM:-none}')."; exit 1
fi
if [ "$MP" != "/data" ]; then
  echo "❌ Pod app does not mount the volume at /data (mountPath='${MP:-none}')."; exit 1
fi
if [ "$PH" != "Running" ]; then
  echo "❌ Pod app is '$PH', expected 'Running'. Give it 'sleep 3600' so it stays up."; exit 1
fi
echo "✅ Pod app is Running with pvc-data mounted at /data"; exit 0
