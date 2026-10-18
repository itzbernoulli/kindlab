#!/bin/bash
CAP=$(kubectl get pv pv-data -o jsonpath='{.spec.capacity.storage}' 2>/dev/null)
AM=$(kubectl get pv pv-data -o jsonpath='{.spec.accessModes[0]}' 2>/dev/null)
HP=$(kubectl get pv pv-data -o jsonpath='{.spec.hostPath.path}' 2>/dev/null)
if [ -z "$CAP" ]; then
  echo "❌ PersistentVolume 'pv-data' not found. Create a hostPath PV."; exit 1
fi
if [ "$CAP" != "1Gi" ]; then
  echo "❌ pv-data capacity is '$CAP', expected '1Gi'."; exit 1
fi
if [ "$AM" != "ReadWriteOnce" ]; then
  echo "❌ pv-data accessMode is '${AM:-none}', expected 'ReadWriteOnce'."; exit 1
fi
if [ "$HP" != "/mnt/data" ]; then
  echo "❌ pv-data hostPath is '${HP:-none}', expected '/mnt/data'."; exit 1
fi
echo "✅ PV pv-data is 1Gi ReadWriteOnce hostPath /mnt/data"; exit 0
