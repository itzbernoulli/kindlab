#!/bin/bash
# Inject a bogus flag into the kube-controller-manager static pod manifest so it
# crash-loops. The learner must diagnose and fix it (no hint) in step 8.
M=/etc/kubernetes/manifests/kube-controller-manager.yaml
docker exec "$CP" sh -c "grep -q 'bogus-flag' $M || sed -i 's#- kube-controller-manager\$#- kube-controller-manager\n    - --bogus-flag=true#' $M"
echo "kube-controller-manager broken on $CP (bogus flag injected) — diagnose & fix in step 8"
