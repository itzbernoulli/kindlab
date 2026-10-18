#!/bin/bash
# Seed the BROKEN HTTPRoute for the step-9 diagnose-and-fix. By now the CRDs are installed
# (step 1) and Gateway web-gw exists (step 3). Resource-level only; never touch the namespace.
NS=gw-learn

kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1

# Safety: ensure the CRDs exist so the seed applies (installed in step 1).
if ! kubectl get crd httproutes.gateway.networking.k8s.io >/dev/null 2>&1 && [ -s /tmp/gateway-api-crds.yaml ]; then
  kubectl apply -f /tmp/gateway-api-crds.yaml >/dev/null 2>&1
fi

# Broken on purpose: parentRefs names a Gateway that doesn't exist, and backendRefs names a
# Service that doesn't exist -> Accepted:False (NoMatchingParent) + ResolvedRefs:False.
kubectl -n "$NS" delete httproute broken-route --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: broken-route
  namespace: gw-learn
spec:
  parentRefs:
  - name: nonexistent-gw
    sectionName: http
  hostnames:
  - hello.example.com
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: ghost-svc
      port: 80
YAML
echo "broken-route seeded (bad parentRef + bad backendRef) — diagnose & fix it in step 9."
