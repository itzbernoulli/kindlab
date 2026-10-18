#!/bin/bash
# Seed Deployment 'draintest' spread across BOTH workers (maxSkew 1, 4 replicas)
# so at least one pod is guaranteed on $W2 — a no-op drain then fails validation.
kubectl delete deployment draintest -n default --ignore-not-found >/dev/null 2>&1
cat <<'YAML' | kubectl apply -f - >/dev/null 2>&1
apiVersion: apps/v1
kind: Deployment
metadata:
  name: draintest
  namespace: default
spec:
  replicas: 4
  selector:
    matchLabels:
      app: draintest
  template:
    metadata:
      labels:
        app: draintest
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: draintest
      containers:
      - name: c
        image: busybox:1.36
        command: ["sh", "-c", "sleep 3600"]
YAML
kubectl -n default rollout status deployment/draintest --timeout=90s >/dev/null 2>&1
echo "seeded Deployment 'draintest' (4 replicas, spread across workers)"
