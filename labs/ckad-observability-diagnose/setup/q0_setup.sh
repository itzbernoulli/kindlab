#!/bin/bash
# Reset the lab by resource (NOT by deleting the namespace, which is slow/racy under load).
# Seeds every broken workload the lab teaches, plus the debug-target pod. Idempotent.
NS=ckad-observability
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete pod crasher bigask logger blackbox --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl -n "$NS" delete deployment web ready-web --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete configmap captured --ignore-not-found >/dev/null 2>&1

# Step 1: CrashLoopBackOff
kubectl -n "$NS" run crasher --image=busybox:1.36 --command -- sh -c 'echo "boot: config file /etc/app.conf not found" >&2; exit 1' >/dev/null 2>&1
# Step 2: ImagePullBackOff Deployment
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: { name: web, labels: { app: web } }
spec:
  replicas: 1
  selector: { matchLabels: { app: web } }
  template:
    metadata: { labels: { app: web } }
    spec:
      containers: [ { name: web, image: nginx:does-not-exist-9999 } ]
YAML
# Step 3: Pending (impossible CPU request)
kubectl -n "$NS" run bigask --image=busybox:1.36 --overrides='{"spec":{"containers":[{"name":"bigask","image":"busybox:1.36","command":["sleep","3600"],"resources":{"requests":{"cpu":"9999"}}}]}}' >/dev/null 2>&1
# Step 5: failing readiness probe
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: { name: ready-web, labels: { app: ready-web } }
spec:
  replicas: 1
  selector: { matchLabels: { app: ready-web } }
  template:
    metadata: { labels: { app: ready-web } }
    spec:
      containers:
      - name: web
        image: nginx:1.25-alpine
        ports: [ { containerPort: 80 } ]
        readinessProbe: { httpGet: { path: /healthz, port: 80 }, initialDelaySeconds: 2, periodSeconds: 3 }
YAML
# Step 6: a running pod to attach an ephemeral debug container to
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: v1
kind: Pod
metadata: { name: blackbox, namespace: ckad-observability }
spec:
  containers: [ { name: app, image: busybox:1.36, command: ["sh","-c","sleep 3600"] } ]
YAML
echo "$NS ready: crasher=CrashLoop, web=ImagePullBackOff, bigask=Pending, ready-web=0 available, blackbox=debug target"
