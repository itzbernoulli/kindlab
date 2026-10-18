#!/bin/bash
TMP=$(mktemp -d)
openssl genrsa -out "$TMP/k.key" 2048 >/dev/null 2>&1
openssl req -new -key "$TMP/k.key" -subj "/CN=learn-dev/O=dev" -out "$TMP/k.csr" >/dev/null 2>&1
REQ=$(base64 < "$TMP/k.csr" | tr -d '\n')
kubectl delete csr learn-dev --ignore-not-found >/dev/null 2>&1
cat <<YAML | kubectl apply -f - >/dev/null 2>&1
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: learn-dev
spec:
  request: $REQ
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
  expirationSeconds: 86400
YAML
echo "seeded pending CSR 'learn-dev'"
