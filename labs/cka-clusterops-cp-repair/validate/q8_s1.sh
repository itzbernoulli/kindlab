#!/bin/bash
# Fail if the seeded fault is still present (learner hasn't fixed the manifest yet).
if docker exec "$CP" grep -q 'bogus-flag' /etc/kubernetes/manifests/kube-controller-manager.yaml 2>/dev/null; then
  echo "❌ the bogus flag is still in /etc/kubernetes/manifests/kube-controller-manager.yaml on $CP. Remove that line so the kubelet can restart it."; exit 1
fi
POD="kube-controller-manager-$CP"
READY=$(kubectl -n kube-system get pod "$POD" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)
if [ "$READY" = "true" ]; then echo "✅ kube-controller-manager is Ready (1/1), fault removed"; exit 0; fi
echo "❌ kube-controller-manager not Ready (ready='${READY:-none}'). After removing the bad flag, give the kubelet ~15s to restart the static pod."; exit 1
