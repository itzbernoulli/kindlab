#!/bin/bash
docker exec "$CP" sh -c 'openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -serial > /tmp/apiserver.orig.serial 2>/dev/null'
echo "recorded original apiserver cert serial on $CP"
