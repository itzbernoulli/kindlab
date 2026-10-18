#!/bin/bash
# Stage the Gateway API manifest locally but DO NOT apply it — installing the CRDs is Step 1.
DEST=/tmp/gateway-api-crds.yaml
VER="v1.1.0"
URL="https://github.com/kubernetes-sigs/gateway-api/releases/download/${VER}/standard-install.yaml"
if [ ! -s "$DEST" ]; then
  curl -fsSL "$URL" -o "$DEST" 2>/dev/null
  if [ ! -s "$DEST" ] && [ -n "$LAB_DIR" ] && [ -f "$LAB_DIR/setup/gateway-api-crds.yaml" ]; then cp "$LAB_DIR/setup/gateway-api-crds.yaml" "$DEST"; fi
fi
# Clean slate: remove gateway objects + the CRDs (student reinstalls in Step 1)
kubectl delete gatewayclass kindlab-gc --ignore-not-found >/dev/null 2>&1
kubectl delete namespace gw-learn --ignore-not-found --wait=true >/dev/null 2>&1
kubectl get crd -o name 2>/dev/null | grep 'gateway.networking.k8s.io' | xargs -r kubectl delete --ignore-not-found >/dev/null 2>&1
# reseed namespace + backend for later steps
kubectl create namespace gw-learn >/dev/null 2>&1
kubectl -n gw-learn create deployment hello --image=nginx:alpine --replicas=1 >/dev/null 2>&1
kubectl -n gw-learn expose deployment hello --name=hello --port=80 >/dev/null 2>&1
echo "gw-learn ready; Gateway API manifest staged at $DEST (install it in Step 1)"
