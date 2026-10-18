#!/bin/bash
# Prepare netpol-learn WITHOUT deleting the namespace (ns delete races under load).
# Ensure the ns + a 'monitoring' source ns exist, remove this lab's policies, re-seed
# labelled pods, and seed a MISCONFIGURED policy 'allow-api' for the step-8 diagnose-fix.
NS=netpol-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
# 'monitoring' is an ingress source namespace (kube auto-labels it with metadata.name)
kubectl get ns monitoring >/dev/null 2>&1 || kubectl create namespace monitoring >/dev/null 2>&1

# resource-level cleanup: drop only the policies this lab builds (keep the namespace)
kubectl -n "$NS" delete networkpolicy \
  default-deny-ingress allow-from-client allow-from-monitoring allow-and \
  default-deny-egress-allow-dns allow-egress-to-db allow-from-cidr allow-api \
  --ignore-not-found >/dev/null 2>&1

# re-seed a few labelled pods (busybox for non-root friendliness); harmless if present
kubectl -n "$NS" run web    --image=busybox:1.36 --restart=Never --labels=app=web     --command -- sleep 3600 >/dev/null 2>&1 || true
kubectl -n "$NS" run db     --image=busybox:1.36 --restart=Never --labels=app=db      --command -- sleep 3600 >/dev/null 2>&1 || true
kubectl -n "$NS" run client --image=busybox:1.36 --restart=Never --labels=role=client --command -- sleep 3600 >/dev/null 2>&1 || true

# step 8 diagnose-fix: 'allow-api' is misconfigured two ways —
#   wrong source label (role=clients, not role=client) AND wrong port (80, not 8080).
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api
  namespace: netpol-learn
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: clients
    ports:
    - protocol: TCP
      port: 80
YAML

echo "netpol-learn ready (pods: web[app=web], db[app=db], client[role=client]; ns 'monitoring' present; broken policy 'allow-api' seeded for step 8; no learner policies present)"
