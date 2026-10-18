#!/bin/bash
# Seed the step-7 diagnose-and-fix: a real TLS Secret 'shop-tls' plus a BROKEN
# Ingress 'shop' whose spec.tls.secretName points at a non-existent Secret
# ('shop-cert') so no cert ever loads. The learner must point it at 'shop-tls'.
# Resource-level only; no namespace delete.
NS=ingress-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1

# ensure the backend exists (in case this step is run first)
kubectl -n "$NS" get deploy web >/dev/null 2>&1 || \
  kubectl -n "$NS" create deployment web --image=nginx:alpine --replicas=1 >/dev/null 2>&1
kubectl -n "$NS" get svc web >/dev/null 2>&1 || \
  kubectl -n "$NS" expose deployment web --name=web --port=80 --target-port=80 >/dev/null 2>&1

# real TLS Secret the Ingress SHOULD reference (CN=shop.example.com)
TMP=$(mktemp -d)
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout "$TMP/tls.key" -out "$TMP/tls.crt" \
  -days 365 -subj "/CN=shop.example.com" >/dev/null 2>&1
kubectl -n "$NS" delete secret shop-tls --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" create secret tls shop-tls --cert="$TMP/tls.crt" --key="$TMP/tls.key" >/dev/null 2>&1
rm -rf "$TMP"

# broken on purpose: spec.tls.secretName references 'shop-cert', which does NOT exist
kubectl apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shop
  namespace: ingress-learn
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - shop.example.com
    secretName: shop-cert
  rules:
  - host: shop.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web
            port:
              number: 80
YAML

echo "seeded broken Ingress 'shop' (spec.tls.secretName=shop-cert is missing; real Secret is shop-tls) — diagnose & fix in step 7"
