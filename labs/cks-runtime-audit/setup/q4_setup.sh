#!/bin/bash
# Pre-create the audit log directory on the control-plane node.
# The CANDIDATE writes the audit policy and edits the kube-apiserver manifest.
# Setup must NOT touch the apiserver manifest (that would risk breaking the API).
docker exec "$CP" mkdir -p /var/log/kubernetes
echo "created /var/log/kubernetes on $CP (candidate adds audit policy + apiserver flags)"
