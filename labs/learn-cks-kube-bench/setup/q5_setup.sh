#!/bin/bash
# Loosen the CA private key permissions to 644 (a CIS violation kube-bench flags).
# Changing only the mode does NOT alter the key or restart anything — fully recoverable.
K=/etc/kubernetes/pki/ca.key
docker exec "$CP" chmod 644 "$K"
echo "ca.key set to 644 on $CP (harden it to 600)"
