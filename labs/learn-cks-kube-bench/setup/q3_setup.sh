#!/bin/bash
# Loosen the kube-scheduler static pod manifest permissions to 644 (a CIS violation
# kube-bench flags as 1.1.x). Changing only the mode does NOT restart the pod, so the
# cluster stays healthy and this is fully recoverable.
M=/etc/kubernetes/manifests/kube-scheduler.yaml
docker exec "$CP" chmod 644 "$M"
echo "kube-scheduler.yaml set to 644 on $CP (harden it to 600)"
