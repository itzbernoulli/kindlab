#!/bin/bash
# Prepare ingress-learn: seed the backend Services (web, api) the Ingress targets.
# Resource-level cleanup only (never delete the namespace).
NS=ingress-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete ingress shop --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: { name: web, namespace: ingress-learn }
spec:
  replicas: 1
  selector: { matchLabels: { app: web } }
  template: { metadata: { labels: { app: web } }, spec: { containers: [ { name: web, image: nginx:1.25 } ] } }
---
apiVersion: v1
kind: Service
metadata: { name: web, namespace: ingress-learn }
spec: { selector: { app: web }, ports: [ { port: 80, targetPort: 80 } ] }
---
apiVersion: apps/v1
kind: Deployment
metadata: { name: api, namespace: ingress-learn }
spec:
  replicas: 1
  selector: { matchLabels: { app: api } }
  template: { metadata: { labels: { app: api } }, spec: { containers: [ { name: api, image: nginx:1.25 } ] } }
---
apiVersion: v1
kind: Service
metadata: { name: api, namespace: ingress-learn }
spec: { selector: { app: api }, ports: [ { port: 80, targetPort: 80 } ] }
YAML
echo "ingress-learn ready (Services web + api seeded; Ingress 'shop' cleared)"
