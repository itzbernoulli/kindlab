#!/bin/bash
NS=workloads-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete deployment web --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete job pi retry bounded indexed stuck --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" delete cronjob report nightly --ignore-not-found >/dev/null 2>&1
# broken Job: parallelism 0 -> no pods run, never completes (step 8 diagnose-fix)
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: batch/v1
kind: Job
metadata: { name: stuck, namespace: workloads-learn }
spec:
  completions: 3
  parallelism: 0
  template:
    spec:
      restartPolicy: Never
      containers: [ { name: c, image: busybox:1.36, command: ["sh","-c","exit 0"] } ]
YAML
echo "workloads-learn ready; broken Job 'stuck' (parallelism:0) seeded for step 8"
