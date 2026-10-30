#!/bin/bash
# Seed ConfigMap + Secret the learner consumes, and a BROKEN pod for the diagnose-fix.
NS=ckad-config
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete pod cfg-env cfg-envfrom cfg-vol sec-pod proj-pod brokencfg --ignore-not-found --force --grace-period=0 >/dev/null 2>&1
kubectl -n "$NS" delete configmap app-config locked-config --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete secret app-secret --ignore-not-found >/dev/null 2>&1
# app-config intentionally has NO GREETING key (that's the step-7 fault) and NO OPTIONAL_KEY
kubectl -n "$NS" create configmap app-config --from-literal=APP_MODE=prod --from-literal=LOG_LEVEL=debug >/dev/null 2>&1
kubectl -n "$NS" create secret generic app-secret --from-literal=API_KEY=xyz123 --from-literal=DB_PASS=s3cr3t >/dev/null 2>&1
# broken pod: references a missing key GREETING -> CreateContainerConfigError until the learner adds it
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: v1
kind: Pod
metadata: { name: brokencfg, namespace: ckad-config }
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh","-c","echo $GREETING; sleep 3600"]
    env:
    - name: GREETING
      valueFrom: { configMapKeyRef: { name: app-config, key: GREETING } }
YAML
echo "ckad-config ready: cm app-config(APP_MODE,LOG_LEVEL), secret app-secret(API_KEY,DB_PASS); broken pod 'brokencfg' seeded for step 7"
