#!/bin/bash
# Prepare ingress-learn for the TLS-at-the-Ingress drills WITHOUT deleting the
# namespace (that races under load). Resource-level cleanup only: ensure the ns
# exists, remove the objects this lab builds, then re-seed the backend app.
# No Secret and no Ingress are seeded here, so steps 1-5 grade real learner work.
NS=ingress-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1

# remove the objects the learner creates / repairs across the lab
kubectl -n "$NS" delete ingress web shop --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete secret web-tls shop-tls --ignore-not-found >/dev/null 2>&1

# (re)seed the backend app: Deployment 'web' + ClusterIP Service 'web' on port 80
kubectl -n "$NS" get deploy web >/dev/null 2>&1 || \
  kubectl -n "$NS" create deployment web --image=nginx:alpine --replicas=1 >/dev/null 2>&1
kubectl -n "$NS" get svc web >/dev/null 2>&1 || \
  kubectl -n "$NS" expose deployment web --name=web --port=80 --target-port=80 >/dev/null 2>&1

echo "ingress-learn ready (Deployment+Service 'web' on port 80; no Secret/Ingress — create web-tls + Ingress 'web' yourself)"
