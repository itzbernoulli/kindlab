#!/bin/bash
# Resource-level reset (never delete the namespace). Seeds pods to label/select + a broken Service.
NS=labels-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete pod frontend legacy shop-a shop-b rel-beta rel-rc rel-stable --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl -n "$NS" delete deployment exp --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete service shop-svc --ignore-not-found >/dev/null 2>&1
mk(){ kubectl -n "$NS" run "$1" --image=nginx:1.25 --labels="$2" >/dev/null 2>&1; }
mk frontend   "app=frontend"
mk legacy     "env=dev,deprecated=true"
mk shop-a     "app=shop"
mk shop-b     "app=shop"
mk rel-beta   "release=beta"
mk rel-rc     "release=rc"
mk rel-stable "release=stable"
# broken Service: selector too specific (tier=cache) — no pod has it -> 0 endpoints
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: v1
kind: Service
metadata: { name: shop-svc, namespace: labels-learn }
spec:
  selector: { app: shop, tier: cache }
  ports: [ { port: 80, targetPort: 80 } ]
YAML
echo "labels-learn ready: pods frontend/legacy/shop-a/shop-b/rel-{beta,rc,stable}; broken Service shop-svc (tier=cache) for step 7"
