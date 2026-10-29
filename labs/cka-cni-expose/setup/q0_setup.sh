#!/bin/bash
# Global reset for learn-cka-cni. RESOURCE-LEVEL cleanup only — we never remove the whole
# namespace (that races under parallel load and wipes the lab). Ensure the ns exists,
# delete just the objects this lab creates, re-seed the web Deployment, and make sure the
# CNI is healthy on every node (in case a prior run left $W2 broken).

NS=cni-learn

# 1) Namespace exists (idempotent, no delete).
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1

# 2) Remove only the objects learners create, so each run starts clean.
kubectl -n "$NS" delete pod netcheck dnscheck client netbroken \
  --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl -n "$NS" delete service web web-hl web-np --ignore-not-found >/dev/null 2>&1

# 3) Heal the CNI on every node (a prior q3 run may have left $W2 without its config).
#    Restarting kindnet makes each pod rewrite /etc/cni/net.d/10-kindnet.conflist.
kubectl -n kube-system rollout restart ds kindnet >/dev/null 2>&1
kubectl -n kube-system rollout status ds kindnet --timeout=90s >/dev/null 2>&1

# 4) Seed the web Deployment used by steps 5-8 (container named 'web', not the image).
if ! kubectl -n "$NS" get deploy web >/dev/null 2>&1; then
  kubectl -n "$NS" create deployment web --image=nginx:alpine --replicas=3 >/dev/null 2>&1
  kubectl -n "$NS" set image deployment/web nginx=nginx:alpine >/dev/null 2>&1
else
  kubectl -n "$NS" scale deployment web --replicas=3 >/dev/null 2>&1
fi
kubectl -n "$NS" rollout status deployment/web --timeout=90s >/dev/null 2>&1

echo "cni-learn ready (web deployment: 3 replicas; CNI healthy on all nodes)"
