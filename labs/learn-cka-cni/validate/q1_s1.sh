#!/bin/bash
IP=$(kubectl get pod netcheck -n cni-learn -o jsonpath='{.status.podIP}' 2>/dev/null)
PH=$(kubectl get pod netcheck -n cni-learn -o jsonpath='{.status.phase}' 2>/dev/null)
if [ -n "$IP" ] && [ "$PH" = "Running" ]; then echo "✅ netcheck is Running with CNI IP $IP"; exit 0; fi
echo "❌ run a Running pod 'netcheck' (busybox sleep) in cni-learn — it should get a CNI IP (got IP='${IP:-none}' phase='${PH:-none}')"; exit 1
