#!/bin/bash
TMP=$(mktemp -d)
openssl genrsa -out "$TMP/dev.key" 2048 >/dev/null 2>&1
openssl req -new -key "$TMP/dev.key" -subj "/CN=developer/O=dev" -out "$TMP/dev.csr" >/dev/null 2>&1
REQ=$(base64 < "$TMP/dev.csr" | tr -d '\n')
kubectl delete csr developer --ignore-not-found >/dev/null 2>&1
cat <<YAML | kubectl apply -f - >/dev/null 2>&1
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: developer
spec:
  request: $REQ
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
  expirationSeconds: 86400
YAML
echo "seeded pending CSR 'developer'"
