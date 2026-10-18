#!/bin/bash
POD="kube-scheduler-$CP"
READY=$(kubectl -n kube-system get pod "$POD" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)
if [ "$READY" = "true" ]; then echo "✅ kube-scheduler is Ready"; exit 0; fi
echo "❌ kube-scheduler not Ready (ready='${READY:-none}'). Remove the bad flag from /etc/kubernetes/manifests/kube-scheduler.yaml on $CP"; exit 1
