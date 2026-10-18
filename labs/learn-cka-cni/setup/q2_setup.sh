#!/bin/bash
# Break the CNI on $W2 by removing its config, then pin a pod there so it hangs without an IP.
kubectl delete pod netbroken -n cni-learn --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
docker exec "$W2" rm -f /etc/cni/net.d/10-kindnet.conflist 2>/dev/null
kubectl run netbroken -n cni-learn --image=busybox:1.36 --overrides="{\"spec\":{\"nodeName\":\"$W2\"}}" --command -- sleep 3600 >/dev/null 2>&1
echo "removed CNI config on $W2; pod 'netbroken' will hang without networking"
