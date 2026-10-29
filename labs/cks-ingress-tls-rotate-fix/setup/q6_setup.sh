#!/bin/bash
# Seed a STALE web-tls Secret (cert CN=old.example.com) + the Ingress 'web' so the
# rotation step is reachable standalone. The learner's job in step 6 is to REPLACE
# the cert in web-tls (same name) with a fresh one for CN=demo.example.com while
# keeping the Ingress reference intact. Resource-level only; no namespace delete.
NS=ingress-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1

# ensure the backend exists (in case this step is run first)
kubectl -n "$NS" get deploy web >/dev/null 2>&1 || \
  kubectl -n "$NS" create deployment web --image=nginx:alpine --replicas=1 >/dev/null 2>&1
kubectl -n "$NS" get svc web >/dev/null 2>&1 || \
  kubectl -n "$NS" expose deployment web --name=web --port=80 --target-port=80 >/dev/null 2>&1

# generate a STALE self-signed cert/key (CN=old.example.com) on the host
TMP=$(mktemp -d)
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout "$TMP/tls.key" -out "$TMP/tls.crt" \
  -days 365 -subj "/CN=old.example.com" >/dev/null 2>&1

# (re)create web-tls with the stale cert
kubectl -n "$NS" delete secret web-tls --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" create secret tls web-tls --cert="$TMP/tls.crt" --key="$TMP/tls.key" >/dev/null 2>&1
rm -rf "$TMP"

# (re)create the Ingress referencing web-tls for demo.example.com
kubectl apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web
  namespace: ingress-learn
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - demo.example.com
    secretName: web-tls
  rules:
  - host: demo.example.com
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

echo "seeded STALE web-tls (CN=old.example.com) + Ingress 'web'; rotate web-tls in place to CN=demo.example.com for step 6"
