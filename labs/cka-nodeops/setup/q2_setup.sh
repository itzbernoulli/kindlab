#!/bin/bash
# Add a bogus flag to the kube-controller-manager static pod manifest so it crash-loops.
# Safe to break: controller-manager is not the apiserver/etcd; the candidate removes the flag.
M=/etc/kubernetes/manifests/kube-controller-manager.yaml
docker exec "$CP" sh -c "grep -q 'bogus-flag' $M || sed -i 's#- kube-controller-manager\$#- kube-controller-manager\n    - --bogus-flag=true#' $M"
echo "kube-controller-manager broken on $CP (bogus flag injected)"
