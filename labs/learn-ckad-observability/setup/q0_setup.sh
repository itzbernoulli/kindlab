#!/bin/bash
# Reset the learn environment to a clean, idempotent slate, then seed every
# broken workload the lab teaches. Safe to re-run; never touches apiserver/etcd.
NS=ckad-observability
kubectl delete namespace "$NS" --ignore-not-found --wait=false >/dev/null 2>&1
# wait for the namespace to be fully gone so recreation is clean
for i in $(seq 1 30); do kubectl get ns "$NS" >/dev/null 2>&1 || break; sleep 1; done
kubectl create namespace "$NS" >/dev/null 2>&1

# Step 1: a CrashLoopBackOff pod (command exits with an error immediately).
kubectl run crasher -n "$NS" --image=busybox:1.36 \
  --command -- sh -c 'echo "boot: config file /etc/app.conf not found" >&2; exit 1' >/dev/null 2>&1

# Step 2: a Deployment whose image tag does not exist (ImagePullBackOff).
cat <<'YAML' | kubectl apply -n "$NS" -f - >/dev/null 2>&1
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  labels:
    app: web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: nginx:does-not-exist-9999
YAML

# Step 3: a pod requesting an impossible amount of CPU (stays Pending).
kubectl run bigask -n "$NS" --image=busybox:1.36 \
  --overrides='{"spec":{"containers":[{"name":"bigask","image":"busybox:1.36","command":["sleep","3600"],"resources":{"requests":{"cpu":"9999"}}}]}}' \
  >/dev/null 2>&1

# Step 5: a Deployment whose readiness probe httpGet path is wrong (stays 0 available).
cat <<'YAML' | kubectl apply -n "$NS" -f - >/dev/null 2>&1
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ready-web
  labels:
    app: ready-web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ready-web
  template:
    metadata:
      labels:
        app: ready-web
    spec:
      containers:
      - name: web
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /healthz
            port: 80
          initialDelaySeconds: 2
          periodSeconds: 3
YAML

echo "$NS ready (seeded: crasher=CrashLoop, web=ImagePullBackOff, bigask=Pending, ready-web=0 available)"
