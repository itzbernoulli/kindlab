#!/bin/bash
# Loosen the kubelet config FILE permissions to 644 on $W1 (CIS 4.1.9 wants <=600).
# This is the diagnose-and-fix: the learner must notice the mode (not the content) is
# the finding. chmod only — nothing restarts, so the node stays Ready.
C=/var/lib/kubelet/config.yaml
docker exec "$W1" chmod 644 "$C"
echo "kubelet config.yaml set to 644 on $W1 (a kube-bench FAIL — find and fix it)"
