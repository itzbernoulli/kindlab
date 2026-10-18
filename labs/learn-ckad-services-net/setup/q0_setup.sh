#!/bin/bash
NS=svcnet-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete service web-svc web-np web-hl db-ext web-sa ext-svc api-svc --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete ingress web-ing --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete endpointslice ext-svc-1 --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete deployment web api --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: { name: web, labels: { app: web } }
spec:
  replicas: 2
  selector: { matchLabels: { app: web } }
  template:
    metadata: { labels: { app: web } }
    spec:
      containers:
      - name: web
        image: nginx:1.25
        ports: [ { name: http, containerPort: 80 } ]
---
apiVersion: apps/v1
kind: Deployment
metadata: { name: api, labels: { app: api } }
spec:
  replicas: 2
  selector: { matchLabels: { app: api } }
  template:
    metadata: { labels: { app: api } }
    spec:
      containers: [ { name: api, image: nginx:1.25, ports: [ { containerPort: 80 } ] } ]
---
apiVersion: v1
kind: Service
metadata: { name: api-svc, namespace: svcnet-learn }
spec:
  selector: { app: api-broken }
  ports: [ { port: 80, targetPort: 80 } ]
YAML
echo "svcnet-learn ready: Deployment web(app=web, named port http) + api(app=api); broken Service api-svc (wrong selector) seeded for step 8"
