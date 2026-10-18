# CKS Runtime, Seccomp & Audit — Answers

> Node names come from `kindlab up`: `kindlab-control-plane`, `kindlab-worker`, `kindlab-worker2`.
> Get a node shell with `docker exec -it <node> bash`. `kubectl` uses the kindlab context automatically (`export KUBECONFIG=kindlab/.state/kubeconfig`).
> In the prompts `$CP`=`kindlab-control-plane`, `$W1`=`kindlab-worker`, `$W2`=`kindlab-worker2`.

## Task 1 — Custom (Localhost) seccomp profile
The kubelet's seccomp root is `/var/lib/kubelet/seccomp`. A `Localhost` profile's `localhostProfile` is a path **relative to that root**, so `profiles/audit.json` → `/var/lib/kubelet/seccomp/profiles/audit.json` on the node where the pod runs.

Place the profile on the worker:
```bash
docker exec -it kindlab-worker bash
mkdir -p /var/lib/kubelet/seccomp/profiles
cat >/var/lib/kubelet/seccomp/profiles/audit.json <<'EOF'
{
  "defaultAction": "SCMP_ACT_LOG"
}
EOF
exit
```
`SCMP_ACT_LOG` logs every syscall (an auditing profile) rather than blocking — perfect for a baseline observe-first profile and it keeps the pod Running.

Create the pod pinned to the worker:
```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: seccomp-audit
  namespace: default
spec:
  nodeName: kindlab-worker
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: profiles/audit.json
  containers:
  - name: c
    image: busybox:1.36
    command: ["sleep", "3600"]
EOF

kubectl get pod seccomp-audit -o wide
```

## Task 2 — RuntimeDefault seccomp profile
```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: seccomp-default
  namespace: default
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: c
    image: busybox:1.36
    command: ["sleep", "3600"]
EOF

kubectl get pod seccomp-default
```
`RuntimeDefault` uses the container runtime's (containerd's) built-in default profile — the baseline CKS wants on every workload.

## Task 3 — Read-only root filesystem
A read-only root FS means the container can't write to `/`. Give it a writable `emptyDir` at `/tmp` so processes needing scratch space still work.
```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: readonly-root
  namespace: default
spec:
  containers:
  - name: c
    image: busybox:1.36
    command: ["sleep", "3600"]
    securityContext:
      readOnlyRootFilesystem: true
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  volumes:
  - name: tmp
    emptyDir: {}
EOF

kubectl get pod readonly-root
```

## Task 4 — API server audit logging
`/var/log/kubernetes` is pre-created by setup. The candidate writes the policy and edits the apiserver manifest.

Write the audit policy on the control-plane:
```bash
docker exec -it kindlab-control-plane bash
cat >/etc/kubernetes/audit-policy.yaml <<'EOF'
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
EOF
```
Still on the node, edit `/etc/kubernetes/manifests/kube-apiserver.yaml`. Add the two flags under `command:` and the matching volume/mount:
```yaml
    - --audit-policy-file=/etc/kubernetes/audit-policy.yaml
    - --audit-log-path=/var/log/kubernetes/audit.log
```
```yaml
    volumeMounts:
    - name: audit-policy
      mountPath: /etc/kubernetes/audit-policy.yaml
      readOnly: true
    - name: audit-log
      mountPath: /var/log/kubernetes
      readOnly: false
  volumes:
  - name: audit-policy
    hostPath:
      path: /etc/kubernetes/audit-policy.yaml
      type: File
  - name: audit-log
    hostPath:
      path: /var/log/kubernetes
      type: DirectoryOrCreate
```
Save and exit. The kubelet restarts the apiserver (static pod) within ~15–60s.
```bash
exit
kubectl -n kube-system get pod kube-apiserver-kindlab-control-plane -w   # wait Running/Ready
docker exec kindlab-control-plane ls -l /var/log/kubernetes/audit.log
```
If the apiserver does not come back, you have a YAML indentation or flag typo — re-open the manifest and fix it (there is no `kubeadm` to repair static pods for you). `docker exec kindlab-control-plane crictl ps -a` + `crictl logs <id>` help debug.

## Task 5 — etcd encryption at rest
`/etc/kubernetes/enc` is pre-created by setup.

Generate a key and write the EncryptionConfiguration on the control-plane:
```bash
docker exec -it kindlab-control-plane bash
KEY=$(head -c 32 /dev/urandom | base64)
cat >/etc/kubernetes/enc/enc.yaml <<EOF
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  providers:
  - aescbc:
      keys:
      - name: key1
        secret: ${KEY}
  - identity: {}
EOF
```
`identity` last = read any still-unencrypted secrets; `aescbc` first = write new ones encrypted. Now edit `/etc/kubernetes/manifests/kube-apiserver.yaml`:
```yaml
    - --encryption-provider-config=/etc/kubernetes/enc/enc.yaml
```
```yaml
    volumeMounts:
    - name: enc
      mountPath: /etc/kubernetes/enc
      readOnly: true
  volumes:
  - name: enc
    hostPath:
      path: /etc/kubernetes/enc
      type: DirectoryOrCreate
```
Save, exit, wait for the apiserver to restart:
```bash
exit
kubectl -n kube-system get pod kube-apiserver-kindlab-control-plane -w
```
Create the secret AFTER encryption is active (existing secrets are not auto-rewritten):
```bash
kubectl create secret generic secret-enc -n default --from-literal=key=supersecret
```
Verify it is encrypted in etcd:
```bash
kubectl -n kube-system exec etcd-kindlab-control-plane -- sh -c \
 'ETCDCTL_API=3 etcdctl \
   --endpoints=https://127.0.0.1:2379 \
   --cacert=/etc/kubernetes/pki/etcd/ca.crt \
   --cert=/etc/kubernetes/pki/etcd/server.crt \
   --key=/etc/kubernetes/pki/etcd/server.key \
   get /registry/secrets/default/secret-enc' | head
# should show  k8s:enc:aescbc:v1:key1:  (not the literal "supersecret")
```
To encrypt all pre-existing secrets too: `kubectl get secrets -A -o json | kubectl replace -f -`.

## Task 6 — ServiceAccount token hardening
```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: restricted
  namespace: default
automountServiceAccountToken: false
---
apiVersion: v1
kind: Pod
metadata:
  name: sa-restricted
  namespace: default
spec:
  serviceAccountName: restricted
  containers:
  - name: c
    image: busybox:1.36
    command: ["sleep", "3600"]
EOF

kubectl get sa restricted -o jsonpath='{.automountServiceAccountToken}{"\n"}'
kubectl get pod sa-restricted -o jsonpath='{.spec.serviceAccountName}{"\n"}'
```
With `automountServiceAccountToken: false` on the SA, no `/var/run/secrets/kubernetes.io/serviceaccount` token is mounted into pods using it — shrinking the blast radius if the container is compromised.
