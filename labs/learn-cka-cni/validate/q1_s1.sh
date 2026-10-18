#!/bin/bash
IP=$(kubectl get pod netcheck -n cni-learn -o jsonpath='{.status.podIP}' 2>/dev/null)
PH=$(kubectl get pod netcheck -n cni-learn -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PH" != "Running" ]; then echo "❌ pod 'netcheck' is not Running (phase='${PH:-none}') — run a busybox:1.36 sleep pod in cni-learn"; exit 1; fi
if [ -z "$IP" ]; then echo "❌ netcheck has no .status.podIP — the CNI hasn't assigned one"; exit 1; fi
case "$IP" in
  10.244.*) echo "✅ netcheck is Running with pod-CIDR IP $IP"; exit 0;;
  *) echo "❌ netcheck IP '$IP' is not in the pod CIDR 10.244.0.0/16"; exit 1;;
esac
