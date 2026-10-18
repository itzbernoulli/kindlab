#!/bin/bash
IP=$(kubectl get pod netbroken -n cni-learn -o jsonpath='{.status.podIP}' 2>/dev/null)
if [ -n "$IP" ]; then echo "✅ CNI restored on $W2 — netbroken now has IP $IP"; exit 0; fi
echo "❌ netbroken still has no IP — reinstall the CNI by restarting kindnet on $W2: kubectl -n kube-system delete pod -l app=kindnet --field-selector spec.nodeName=$W2"; exit 1
