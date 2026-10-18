#!/bin/bash
# Seed four already-running Deployments + a ConfigMap at a known baseline so the learner
# MODIFIES them in place (scale/update/rollback/resources/env/strategy/patch/restart).
# Idempotent: delete + recreate so every Start/Reset returns to baseline.
NS=deploy-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete deployment frontend api cache worker --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete configmap worker-cfg --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" create configmap worker-cfg --from-literal=LOG_LEVEL=info --from-literal=REGION=eu >/dev/null 2>&1

kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: { name: frontend, labels: { app: frontend } }
spec:
  replicas: 2
  selector: { matchLabels: { app: frontend } }
  template:
    metadata: { labels: { app: frontend } }
    spec:
      containers: [ { name: frontend, image: nginx:1.25 } ]
---
apiVersion: apps/v1
kind: Deployment
metadata: { name: api, labels: { app: api } }
spec:
  replicas: 3
  selector: { matchLabels: { app: api } }
  template:
    metadata: { labels: { app: api } }
    spec:
      containers: [ { name: api, image: nginx:1.25 } ]
---
apiVersion: apps/v1
kind: Deployment
metadata: { name: cache, labels: { app: cache } }
spec:
  replicas: 2
  selector: { matchLabels: { app: cache } }
  template:
    metadata: { labels: { app: cache } }
    spec:
      containers: [ { name: cache, image: nginx:1.25 } ]
---
apiVersion: apps/v1
kind: Deployment
metadata: { name: worker, labels: { app: worker } }
spec:
  replicas: 1
  selector: { matchLabels: { app: worker } }
  template:
    metadata: { labels: { app: worker } }
    spec:
      containers: [ { name: worker, image: busybox:1.36, command: ["sh","-c","sleep 3600"] } ]
YAML
echo "seeded deploy-learn: frontend(2) api(3,nginx:1.25) cache(2) worker(1) + configmap worker-cfg(LOG_LEVEL,REGION)"
