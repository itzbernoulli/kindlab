#!/bin/bash
# Reset the learn environment to a clean slate (idempotent).
kubectl delete namespace cks-supply --ignore-not-found --wait=false >/dev/null 2>&1
kubectl delete validatingadmissionpolicybinding approved-registry-binding --ignore-not-found >/dev/null 2>&1
kubectl delete validatingadmissionpolicy approved-registry --ignore-not-found >/dev/null 2>&1
# wait for namespace to disappear so recreate is clean
for i in $(seq 1 30); do
  kubectl get ns cks-supply >/dev/null 2>&1 || break
  sleep 1
done
kubectl create namespace cks-supply >/dev/null 2>&1
# seed the manifest ConfigMap used by the kubesec step
cat <<'YAML' >/tmp/kubesec-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: sample
spec:
  containers:
  - name: app
    image: nginx:1.25-alpine
YAML
kubectl -n cks-supply delete configmap kubesec-manifest --ignore-not-found >/dev/null 2>&1
kubectl -n cks-supply create configmap kubesec-manifest --from-file=pod.yaml=/tmp/kubesec-pod.yaml >/dev/null 2>&1
echo "cks-supply ready (kubesec-manifest ConfigMap seeded)"
