#!/bin/bash
# Reset the learn environment to a clean slate (idempotent).
# ingress-learn: seeded with a web Deployment + Service so the learner's job is
# the TLS Secret + Ingress work. No Secret, no Ingress are seeded, so every
# step is graded on real learner work (nothing passes on an untouched cluster).
kubectl delete namespace ingress-learn --ignore-not-found --wait=false >/dev/null 2>&1

# wait for the namespace to be fully gone before recreating
for i in $(seq 1 30); do kubectl get ns ingress-learn >/dev/null 2>&1 || break; sleep 1; done

kubectl create namespace ingress-learn >/dev/null 2>&1

# seed the backend app: Deployment 'web' + ClusterIP Service 'web' on port 80
kubectl -n ingress-learn create deployment web --image=nginx:alpine --replicas=1 >/dev/null 2>&1 || true
kubectl -n ingress-learn expose deployment web --name=web --port=80 --target-port=80 >/dev/null 2>&1 || true

# make sure no leftover Secret/Ingress from a prior run — the learner must create them
kubectl -n ingress-learn delete secret web-tls --ignore-not-found >/dev/null 2>&1 || true
kubectl -n ingress-learn delete ingress web --ignore-not-found >/dev/null 2>&1 || true

echo "ingress-learn ready (Deployment+Service 'web' on port 80; no Secret/Ingress — create web-tls + Ingress yourself)"
