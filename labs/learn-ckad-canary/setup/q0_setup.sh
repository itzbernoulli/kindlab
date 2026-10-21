#!/bin/bash
# Resource-level reset (never delete the namespace). Seeds a broken 'pay' canary for step 5.
NS=canary-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete deployment web-stable web-canary pay-stable pay-canary --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete service web pay --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: { name: pay-stable, namespace: canary-learn }
spec:
  replicas: 2
  selector: { matchLabels: { app: pay, track: stable } }
  template:
    metadata: { labels: { app: pay, track: stable } }
    spec: { containers: [ { name: web, image: nginx:1.25 } ] }
---
apiVersion: apps/v1
kind: Deployment
metadata: { name: pay-canary, namespace: canary-learn }
spec:
  replicas: 1
  selector: { matchLabels: { app: pay, track: canary } }
  template:
    metadata: { labels: { app: pay, track: canary } }
    spec: { containers: [ { name: web, image: nginx:1.26 } ] }
---
apiVersion: v1
kind: Service
metadata: { name: pay, namespace: canary-learn }
spec:
  selector: { app: pay, track: stable }
  ports: [ { port: 80, targetPort: 80 } ]
YAML
echo "canary-learn ready; broken Service 'pay' (selector too specific: track=stable) seeded for step 5"
