#!/bin/bash
# Loosen the kube-scheduler static pod manifest permissions to 644 (CIS violation).
# Changing the mode does NOT restart the pod, so the cluster stays healthy.
M=/etc/kubernetes/manifests/kube-scheduler.yaml
docker exec "$CP" sh -c "chmod 644 $M"
echo "kube-scheduler.yaml set to 644 on $CP (candidate must harden to 600)"
