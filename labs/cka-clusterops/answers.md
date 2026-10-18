# CKA Cluster Operations — Answers

> Node names come from `kindlab up`: `kindlab-control-plane`, `kindlab-worker`, `kindlab-worker2`.
> Get a node shell with `docker exec -it <node> bash`. `kubectl` uses the kindlab context automatically (`export KUBECONFIG=kindlab/.state/kubeconfig`).

## Task 1 — Static pod on a worker
A static pod is created by the kubelet directly from a manifest in `/etc/kubernetes/manifests/` on a node (no API server involved). The API server shows a read-only **mirror pod** named `<pod-name>-<node-name>`.

```bash
docker exec -it kindlab-worker bash
cat >/etc/kubernetes/manifests/static-web.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: static-web
spec:
  containers:
  - name: web
    image: nginx:alpine
EOF
exit

# mirror pod appears as static-web-kindlab-worker
kubectl get pod static-web-kindlab-worker -n default
```

## Task 2 — Repair the broken kube-scheduler
A control-plane component (apiserver, scheduler, controller-manager, etcd) runs as a **static pod** from `/etc/kubernetes/manifests/` on the control-plane. A bad flag makes it crash-loop; remove it and the kubelet restarts it.

```bash
docker exec -it kindlab-control-plane bash
grep -n bogus /etc/kubernetes/manifests/kube-scheduler.yaml      # find the bad line
sed -i '/--bogus-flag=true/d' /etc/kubernetes/manifests/kube-scheduler.yaml
exit

# kubelet restarts the static pod within ~15s
kubectl -n kube-system get pod kube-scheduler-kindlab-control-plane -w
```
Troubleshooting a down component: `kubectl -n kube-system describe pod kube-scheduler-...`, or on the node `crictl ps -a` + `crictl logs <id>`, or `journalctl -u kubelet`.

## Task 3 — Approve the CSR
```bash
kubectl get csr                              # 'developer' is Pending
kubectl certificate approve developer
kubectl get csr developer                    # Approved,Issued
```
(To build a usable kubeconfig for the user you'd then extract the cert: `kubectl get csr developer -o jsonpath='{.status.certificate}' | base64 -d > developer.crt` and wire it with `kubectl config set-credentials/set-context`.)

## Task 4 — Cordon and drain a node
```bash
kubectl cordon kindlab-worker2
kubectl drain kindlab-worker2 --ignore-daemonsets --delete-emptydir-data
# maintenance done → bring it back:
kubectl uncordon kindlab-worker2
```
`cordon` sets `spec.unschedulable=true` (no *new* pods). `drain` also evicts existing pods (skipping DaemonSets, optionally deleting emptyDir data).

## Task 5 — Back up etcd
etcd runs as a static pod and already has `etcdctl` + the certs inside it. Save into `/var/lib/etcd` (mounted on the node), then copy to `/opt`.

> Note: the etcd image is **distroless — no shell** — so call `etcdctl` *directly* (not via `sh -c`). Recent `etcdctl` defaults to the v3 API, so `ETCDCTL_API=3` isn't needed.

```bash
# take the snapshot from inside the etcd pod (etcdctl called directly)
kubectl -n kube-system exec etcd-kindlab-control-plane -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /var/lib/etcd/snapshot.db

# copy it to /opt/snapshot.db on the control-plane node
docker exec kindlab-control-plane cp /var/lib/etcd/snapshot.db /opt/snapshot.db

# verify
docker exec kindlab-control-plane sh -c \
 'ETCDCTL_API=3 etcdctl snapshot status /opt/snapshot.db -w table' 2>/dev/null || true
```

**Restore** (not graded here, but know it): `etcdctl snapshot restore /opt/snapshot.db --data-dir /var/lib/etcd-restore`, then point `/etc/kubernetes/manifests/etcd.yaml`'s hostPath volume at the restored dir and let the kubelet restart etcd.
