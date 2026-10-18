#!/bin/bash
# Seed a baseline web-tls Secret + Ingress 'web' so the rotation step is reachable
# on its own. Idempotent. The learner's job in step 5 is to REPLACE the cert in
# web-tls (same name) while keeping the Ingress reference intact.
NS=ingress-learn

# ensure namespace + backend exist (in case this step is run standalone)
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" get deploy web >/dev/null 2>&1 || kubectl -n "$NS" create deployment web --image=nginx:alpine --replicas=1 >/dev/null 2>&1
kubectl -n "$NS" get svc web >/dev/null 2>&1 || kubectl -n "$NS" expose deployment web --name=web --port=80 --target-port=80 >/dev/null 2>&1

# generate a baseline self-signed cert/key on the host
TMP=$(mktemp -d)
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout "$TMP/tls.key" -out "$TMP/tls.crt" \
  -days 365 -subj "/CN=demo.example.com" >/dev/null 2>&1

# (re)create the baseline web-tls Secret
kubectl -n "$NS" delete secret web-tls --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" create secret tls web-tls --cert="$TMP/tls.crt" --key="$TMP/tls.key" >/dev/null 2>&1

# (re)create the Ingress referencing web-tls for demo.example.com
cat <<'YAML' | kubectl apply -f - >/dev/null 2>&1
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web
  namespace: ingress-learn
spec:
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

rm -rf "$TMP"
echo "seeded baseline web-tls Secret + Ingress 'web' (rotate web-tls in place for step 5)"
# record the baseline cert fingerprint so the rotation check can require a CHANGE
if [ -n "$LAB_DIR" ]; then
  kubectl -n ingress-learn get secret web-tls -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d 2>/dev/null \
    | openssl x509 -noout -fingerprint -sha256 2>/dev/null > "$LAB_DIR/.webtls-baseline"
fi
