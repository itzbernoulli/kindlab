#!/bin/bash
# Fail if the bogus flag is still present (learner hasn't fixed the manifest yet).
if docker exec "$CP" grep -q 'bogus-flag' /etc/kubernetes/manifests/kube-scheduler.yaml 2>/dev/null; then
  echo "❌ the bogus flag is still in /etc/kubernetes/manifests/kube-scheduler.yaml on $CP. Remove that line so the kubelet can restart the scheduler."; exit 1
fi
POD="kube-scheduler-$CP"
READY=$(kubectl -n kube-system get pod "$POD" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)
if [ "$READY" = "true" ]; then echo "✅ kube-scheduler is Ready"; exit 0; fi
echo "❌ kube-scheduler not Ready (ready='${READY:-none}'). After removing the bad flag, give the kubelet ~15s to restart the static pod."; exit 1
