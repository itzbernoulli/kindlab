#!/bin/bash
# Reset the learn environment to a clean slate (idempotent).
# netpol-learn: seeded with labelled pods and NO NetworkPolicies so grading
# reflects the learner's work. A 'monitoring' namespace is created as a source.
kubectl delete namespace netpol-learn --ignore-not-found --wait=false >/dev/null 2>&1

# wait for namespace to be fully gone before recreating
for i in $(seq 1 30); do kubectl get ns netpol-learn >/dev/null 2>&1 || break; sleep 1; done

kubectl create namespace netpol-learn >/dev/null 2>&1
# ensure a 'monitoring' namespace exists as an ingress source (kube auto-labels it)
kubectl create namespace monitoring >/dev/null 2>&1 || true

# seed a few labelled pods (busybox for non-root friendliness)
kubectl -n netpol-learn run web    --image=busybox:1.36 --restart=Never --labels=app=web            --command -- sleep 3600 >/dev/null 2>&1 || true
kubectl -n netpol-learn run db     --image=busybox:1.36 --restart=Never --labels=app=db             --command -- sleep 3600 >/dev/null 2>&1 || true
kubectl -n netpol-learn run client --image=busybox:1.36 --restart=Never --labels=role=client        --command -- sleep 3600 >/dev/null 2>&1 || true

# remove any pre-existing policies so the slate is clean
kubectl -n netpol-learn delete networkpolicy --all >/dev/null 2>&1 || true

echo "netpol-learn ready (pods: web[app=web], db[app=db], client[role=client]; namespace 'monitoring' present; no NetworkPolicies)"
