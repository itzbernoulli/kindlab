#!/bin/bash
# Read the raw Secret value directly from etcd via the etcd pod's etcdctl.
# An encrypted secret begins with k8s:enc:aescbc: ; plaintext would start with k8s:\n (contains readable value).
if ! kubectl get secret secret-enc -n default >/dev/null 2>&1; then
  echo "❌ Secret 'default/secret-enc' does not exist — create it after enabling encryption"; exit 1
fi
ETCD="etcd-$CP"
RAW=$(kubectl -n kube-system exec "$ETCD" -- sh -c \
  'ETCDCTL_API=3 etcdctl \
    --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key \
    get /registry/secrets/default/secret-enc' 2>/dev/null)
if echo "$RAW" | grep -q 'k8s:enc:aescbc:'; then
  echo "✅ Secret secret-enc is encrypted at rest (k8s:enc:aescbc: prefix in etcd)"; exit 0
fi
if echo "$RAW" | grep -q 'supersecret'; then
  echo "❌ Secret secret-enc is stored in PLAINTEXT in etcd — re-create it AFTER enabling encryption (existing secrets are not auto-rewritten)"; exit 1
fi
echo "❌ Secret secret-enc is not encrypted with aescbc in etcd (no k8s:enc:aescbc: prefix found). Check EncryptionConfiguration and that the apiserver reloaded it, then re-create the secret"; exit 1
