#!/bin/bash
# Ensure the apiserver has NO --profiling flag so the learner must add --profiling=false.
# --profiling defaults to true, so an absent flag == non-compliant (the whole point).
# Only removes the --profiling line; leaves --enable-admission-plugins (step 4) intact.
M=/etc/kubernetes/manifests/kube-apiserver.yaml
docker exec "$CP" sed -i '/--profiling=/d' "$M"
echo "removed any --profiling flag from kube-apiserver on $CP (add --profiling=false). Waiting for restart..."
sleep 10
