#!/bin/bash
PH=$(kubectl -n storage-learn get pvc pvc-data -o jsonpath='{.status.phase}' 2>/dev/null)
VN=$(kubectl -n storage-learn get pvc pvc-data -o jsonpath='{.spec.volumeName}' 2>/dev/null)
if [ -z "$PH" ]; then
  echo "❌ PVC 'pvc-data' not found in namespace storage-learn."; exit 1
fi
if [ "$PH" != "Bound" ]; then
  echo "❌ pvc-data status is '$PH', expected 'Bound'. Check that class/size/accessMode match pv-data."; exit 1
fi
if [ "$VN" != "pv-data" ]; then
  echo "❌ pvc-data bound to '${VN:-none}', expected 'pv-data'. Set spec.volumeName: pv-data."; exit 1
fi
echo "✅ PVC pvc-data is Bound to pv-data"; exit 0
