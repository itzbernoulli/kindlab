#!/bin/bash
# Inject a bogus flag into the kube-scheduler static pod manifest so it crash-loops.
M=/etc/kubernetes/manifests/kube-scheduler.yaml
docker exec "$CP" sh -c "grep -q 'bogus-flag' $M || sed -i 's#- kube-scheduler\$#- kube-scheduler\n    - --bogus-flag=true#' $M"
echo "kube-scheduler broken on $CP (bogus flag injected)"
