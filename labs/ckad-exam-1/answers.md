# CKAD Practice Exam — Core — Answers

> All tasks run against namespace `exam` (created/reset by `setup/q0_setup.sh`).
> `kubectl` already targets the kindlab context (`KUBECONFIG` is exported). Non-root pods use `busybox:1.36`.
> Set a default once if you like: `kubectl config set-context --current --namespace=exam`.

## Task 1 — Deployment with replicas and scaling
```bash
kubectl -n exam create deployment web --image=nginx:1.25 --replicas=4
# pod template already gets label app=web from `create deployment`; verify:
kubectl -n exam get deploy web -o jsonpath='{.spec.template.metadata.labels}'; echo
# scale up
kubectl -n exam scale deployment web --replicas=6
kubectl -n exam rollout status deployment web
```

## Task 2 — Rolling update to a new image
`roller` is seeded at `nginx:1.24`.
```bash
kubectl -n exam set image deployment/roller nginx=nginx:1.25
kubectl -n exam rollout status deployment/roller
```
(`nginx` is the container name produced by `kubectl create deployment roller --image=nginx:1.24`.)

## Task 3 — Multi-container pod sharing an emptyDir
```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: sidecar
  namespace: exam
spec:
  volumes:
  - name: shared
    emptyDir: {}
  containers:
  - name: writer
    image: busybox:1.36
    command: ["sh","-c","while true; do date >> /data/out.txt; sleep 5; done"]
    volumeMounts:
    - name: shared
      mountPath: /data
  - name: reader
    image: busybox:1.36
    command: ["sh","-c","tail -f /data/out.txt"]
    volumeMounts:
    - name: shared
      mountPath: /data
EOF
```

## Task 4 — Init container pattern
```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: initdemo
  namespace: exam
spec:
  volumes:
  - name: work
    emptyDir: {}
  initContainers:
  - name: setup
    image: busybox:1.36
    command: ["sh","-c","echo ready > /work/status"]
    volumeMounts:
    - name: work
      mountPath: /work
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh","-c","cat /work/status && sleep 3600"]
    volumeMounts:
    - name: work
      mountPath: /work
EOF
```

## Task 5 — ConfigMap + Secret wired into a pod
```bash
kubectl -n exam create configmap app-cfg --from-literal=APP_MODE=production
kubectl -n exam create secret generic app-sec --from-literal=API_KEY=s3cr3t

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: consumer
  namespace: exam
spec:
  volumes:
  - name: sec
    secret:
      secretName: app-sec
  containers:
  - name: main
    image: busybox:1.36
    command: ["sh","-c","sleep 3600"]
    env:
    - name: APP_MODE
      valueFrom:
        configMapKeyRef:
          name: app-cfg
          key: APP_MODE
    volumeMounts:
    - name: sec
      mountPath: /etc/secret
EOF
```

## Task 6 — Resource requests and limits
```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: limited
  namespace: exam
spec:
  containers:
  - name: main
    image: busybox:1.36
    command: ["sh","-c","sleep 3600"]
    resources:
      requests:
        cpu: "100m"
        memory: "64Mi"
      limits:
        cpu: "250m"
        memory: "128Mi"
EOF
```

## Task 7 — Liveness + readiness probes
```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: probed
  namespace: exam
spec:
  containers:
  - name: web
    image: nginx:1.25
    ports:
    - containerPort: 80
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 10
EOF
```

## Task 8 — ClusterIP Service for a deployment
`clip` deployment is seeded (app=clip, port 80).
```bash
kubectl -n exam expose deployment clip --name=clip-svc --type=ClusterIP --port=80 --target-port=80
kubectl -n exam get endpoints clip-svc
```

## Task 9 — NodePort Service on a specific port
`np` deployment is seeded (app=np, port 80).
```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: np-svc
  namespace: exam
spec:
  type: NodePort
  selector:
    app: np
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
EOF
```

## Task 10 — Ingress host/path rule
```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shop-ing
  namespace: exam
spec:
  rules:
  - host: shop.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: clip-svc
            port:
              number: 80
EOF
```

## Task 11 — NetworkPolicy default-deny + allow-from-label
```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: exam
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web
  namespace: exam
spec:
  podSelector:
    matchLabels:
      app: clip
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
EOF
```

## Task 12 — Job with completions/parallelism
```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: pi-job
  namespace: exam
spec:
  completions: 4
  parallelism: 2
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: work
        image: busybox:1.36
        command: ["sh","-c","echo done"]
EOF
kubectl -n exam wait --for=condition=complete job/pi-job --timeout=120s
```

## Task 13 — CronJob with a schedule
```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: batch/v1
kind: CronJob
metadata:
  name: beat
  namespace: exam
spec:
  schedule: "*/5 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
          - name: beat
            image: busybox:1.36
            command: ["sh","-c","date"]
EOF
```

## Task 14 — ServiceAccount used by a pod
```bash
kubectl -n exam create serviceaccount app-sa
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: sa-pod
  namespace: exam
spec:
  serviceAccountName: app-sa
  containers:
  - name: main
    image: busybox:1.36
    command: ["sh","-c","sleep 3600"]
EOF
```

## Task 15 — Pod securityContext (runAsNonRoot + drop caps)
```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: hardened
  namespace: exam
spec:
  containers:
  - name: main
    image: busybox:1.36
    command: ["sh","-c","sleep 3600"]
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
EOF
```
