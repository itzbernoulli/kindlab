#!/bin/bash
# Seed a broken Job for step 2: the 'helper' is a PLAIN container that runs
# forever, so the Job never completes. The learner must make it a native sidecar.
NS=sidecar-learn
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create namespace "$NS" >/dev/null 2>&1
kubectl -n "$NS" delete job batch-job --ignore-not-found >/dev/null 2>&1
kubectl -n "$NS" apply -f - >/dev/null 2>&1 <<'YAML'
apiVersion: batch/v1
kind: Job
metadata: { name: batch-job, namespace: sidecar-learn }
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: worker
        image: busybox:1.36
        command: ["sh","-c","echo working; sleep 5; echo done"]
      - name: helper
        image: busybox:1.36
        command: ["sh","-c","while true; do echo helping; sleep 5; done"]
YAML
echo "seeded broken Job batch-job (plain 'helper' runs forever → never completes) — fix it with a native sidecar"
