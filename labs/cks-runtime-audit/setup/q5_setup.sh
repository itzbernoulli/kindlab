#!/bin/bash
# Pre-create the encryption-config directory on the control-plane node.
# The CANDIDATE writes the EncryptionConfiguration and edits the kube-apiserver manifest.
# Setup must NOT touch the apiserver manifest (that would risk breaking the API).
docker exec "$CP" mkdir -p /etc/kubernetes/enc
echo "created /etc/kubernetes/enc on $CP (candidate adds EncryptionConfiguration + apiserver flag)"
