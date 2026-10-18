#!/bin/bash
# Stop the kubelet on worker $W1 so the node goes NotReady.
# Candidate restarts it; this is safely recoverable (worker only, not apiserver/etcd).
docker exec "$W1" systemctl stop kubelet >/dev/null 2>&1
echo "kubelet stopped on $W1 (node will go NotReady)"
