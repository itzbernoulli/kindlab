#!/bin/bash
# Prepare the Gateway API lab. Resource-level cleanup only (NEVER delete the namespace —
# that races under parallel load). Stage the CRD manifest; the learner installs it in step 1.
NS=gw-learn

# Stage the standard-channel Gateway API manifest locally (do NOT apply — that's step 1).
DEST=/tmp/gateway-api-crds.yaml
VER="v1.1.0"
URL="https://github.com/kubernetes-sigs/gateway-api/releases/download/${VER}/standard-install.yaml"
if [ ! -s "$DEST" ]; then
  curl -fsSL "$URL" -o "$DEST" 2>/dev/null
  if [ ! -s "$DEST" ] && [ -n "$LAB_DIR" ] && [ -f "$LAB_DIR/setup/gateway-api-crds.yaml" ]; then
    cp "$LAB_DIR/setup/gateway-api-crds.yaml" "$DEST"
  fi
fi

# Ensure namespace exists (create if missing; never delete it).
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1

# Cluster-scoped cleanup: drop the GatewayClass the learner recreates.
kubectl delete gatewayclass kindlab-gc --ignore-not-found >/dev/null 2>&1

# If the CRDs are present, clean the Gateway/HTTPRoute objects this lab builds so re-runs start fresh.
if kubectl get crd httproutes.gateway.networking.k8s.io >/dev/null 2>&1; then
  kubectl -n "$NS" delete httproute web-route canary-route hdr-route split-route broken-route \
    --ignore-not-found >/dev/null 2>&1
fi
if kubectl get crd gateways.gateway.networking.k8s.io >/dev/null 2>&1; then
  kubectl -n "$NS" delete gateway web-gw --ignore-not-found >/dev/null 2>&1
fi
kubectl -n "$NS" delete ingress web-ing --ignore-not-found >/dev/null 2>&1

# Backends the HTTPRoutes/Ingress forward to.
kubectl -n "$NS" get deploy hello >/dev/null 2>&1 || \
  kubectl -n "$NS" create deployment hello --image=nginx:alpine --replicas=1 >/dev/null 2>&1
kubectl -n "$NS" get svc hello >/dev/null 2>&1 || \
  kubectl -n "$NS" expose deployment hello --name=hello --port=80 >/dev/null 2>&1
kubectl -n "$NS" get deploy hello-canary >/dev/null 2>&1 || \
  kubectl -n "$NS" create deployment hello-canary --image=nginx:alpine --replicas=1 >/dev/null 2>&1
kubectl -n "$NS" get svc hello-canary >/dev/null 2>&1 || \
  kubectl -n "$NS" expose deployment hello-canary --name=hello-canary --port=80 >/dev/null 2>&1

echo "gw-learn ready: Services hello + hello-canary seeded; Gateway API manifest staged at $DEST (install it in step 1)."
