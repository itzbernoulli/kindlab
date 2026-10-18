#!/bin/bash
# Disable NodeRestriction on the apiserver so the candidate must re-enable it.
# (kind/kubeadm enables it by default, so without this the task would always pass.)
M=/etc/kubernetes/manifests/kube-apiserver.yaml
docker exec "$CP" sh -c "
  sed -i 's/,NodeRestriction//; s/NodeRestriction,//; s/=NodeRestriction/=/' $M
  # if the flag value is now empty, remove the whole line
  sed -i '/--enable-admission-plugins=$/d' $M
"
echo "NodeRestriction disabled on kube-apiserver (candidate must re-enable). Waiting for restart..."
sleep 10
