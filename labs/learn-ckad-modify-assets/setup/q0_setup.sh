#!/bin/bash
# Seed four pre-existing assets that each need a "not straightforward" modification.
# Idempotent: deletes then recreates so every Start/Reset returns to baseline.
NS=modify-learn
AST=/tmp/kindlab-assets
mkdir -p "$AST"
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete deployment legacy widget web --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete pod tool --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete configmap web-config --ignore-not-found >/dev/null 2>&1
rm -f "$AST/widget-deploy.yaml"

# Step 1 — Deployment 'legacy' with immutable selector app=legacy
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: { name: legacy, labels: { app: legacy } }
spec:
  replicas: 1
  selector: { matchLabels: { app: legacy } }
  template:
    metadata: { labels: { app: legacy } }
    spec:
      containers: [ { name: app, image: nginx:1.25 } ]
YAML

# Step 2 — bare Pod 'tool' with no env (immutable in place)
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: v1
kind: Pod
metadata: { name: tool, labels: { app: tool } }
spec:
  containers:
  - { name: tool, image: busybox:1.36, command: ["sh","-c","sleep 3600"] }
YAML

# Step 3 — on-disk manifest for Deployment 'widget', applied at replicas=1 / nginx:1.25
cat > "$AST/widget-deploy.yaml" <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: widget
  namespace: modify-learn
  labels: { app: widget }
spec:
  replicas: 1
  selector: { matchLabels: { app: widget } }
  template:
    metadata: { labels: { app: widget } }
    spec:
      containers:
      - name: widget
        image: nginx:1.25
YAML
kubectl apply -f "$AST/widget-deploy.yaml" >/dev/null 2>&1

# Step 4 — ConfigMap web-config (COLOR=blue) + Deployment web reading it via env
kubectl -n "$NS" create configmap web-config --from-literal=COLOR=blue >/dev/null 2>&1
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
        env:
        - name: COLOR
          valueFrom: { configMapKeyRef: { name: web-config, key: COLOR } }
YAML

echo "seeded modify-learn: Deployment legacy, Pod tool, Deployment widget (<- $AST/widget-deploy.yaml), Deployment web + cm web-config(COLOR=blue)"
