#!/bin/bash
# Reset the learn environment to a clean, idempotent slate so Start/Reset always works.
# svcnet-learn: seeded with two Deployments (web, api) and nothing else.
#   - web: 3 replicas, label app=web, container port 8080  (for Service/NodePort/Ingress steps)
#   - api: 2 replicas, label app=api                        (backs the broken Service in step 5,
#          created later by q5_setup.sh with the WRONG selector)
# No Services / Ingress / NetworkPolicies are created here, so grading reflects the learner's work.
kubectl delete namespace svcnet-learn --ignore-not-found --wait=false >/dev/null 2>&1

# wait for namespace to be fully gone before recreating
for i in $(seq 1 30); do kubectl get ns svcnet-learn >/dev/null 2>&1 || break; sleep 1; done

kubectl create namespace svcnet-learn >/dev/null 2>&1

# web Deployment: 3 replicas, app=web, listens on 8080 (busybox httpd-free placeholder)
cat <<'YAML' | kubectl apply -f - >/dev/null 2>&1
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: svcnet-learn
  labels:
    app: web
spec:
  replicas: 3
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
        image: busybox:1.36
        command: ["sh","-c","sleep 3600"]
        ports:
        - containerPort: 8080
YAML

# api Deployment: 2 replicas, label app=api (its Service is seeded broken in q5_setup.sh)
cat <<'YAML' | kubectl apply -f - >/dev/null 2>&1
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: svcnet-learn
  labels:
    app: api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: busybox:1.36
        command: ["sh","-c","sleep 3600"]
        ports:
        - containerPort: 8080
YAML

# ensure no leftover learner objects remain
kubectl -n svcnet-learn delete svc --all >/dev/null 2>&1 || true
kubectl -n svcnet-learn delete ingress --all >/dev/null 2>&1 || true
kubectl -n svcnet-learn delete networkpolicy --all >/dev/null 2>&1 || true

echo "svcnet-learn ready (Deployments: web[app=web,3x,:8080], api[app=api,2x]; no Services/Ingress/NetworkPolicies)"
