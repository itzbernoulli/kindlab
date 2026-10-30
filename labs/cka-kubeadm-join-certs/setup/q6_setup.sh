#!/bin/bash
# Step 6 (cert renew): record the CURRENT apiserver cert serial on $CP so the validator
# can prove the learner wrote a fresh cert (serial must change after renew).
docker exec "$CP" sh -c 'openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -serial > /tmp/apiserver.orig.serial 2>/dev/null'
echo "recorded original apiserver cert serial on $CP"
