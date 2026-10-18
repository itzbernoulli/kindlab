#!/bin/bash
POD="kube-controller-manager-$CP"
READY=$(kubectl -n kube-system get pod "$POD" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)
if [ "$READY" = "true" ]; then echo "✅ kube-controller-manager is Ready"; exit 0; fi
echo "❌ kube-controller-manager not Ready (ready='${READY:-none}'). Remove the bad flag from /etc/kubernetes/manifests/kube-controller-manager.yaml on $CP"; exit 1
