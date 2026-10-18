# Learn: Cluster Operations — Answers

> Node names come from `kindlab up`: `kindlab-control-plane` (`$CP`), `kindlab-worker` (`$W1`), `kindlab-worker2` (`$W2`).
> Node shell: `docker exec -it <node> bash`. `kubectl` uses the kindlab context automatically.

## Step 1 — Static pod on a worker
The kubelet runs static pods directly from `/etc/kubernetes/manifests/` on a node; the API server shows a read-only mirror pod `<name>-<node>`.

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
    image: busybox:1.36
    command: ["sleep","3600"]
EOF
exit
kubectl get pod static-web-kindlab-worker -n default   # wait for Running
```

## Step 2 — Repair the broken kube-scheduler
Control-plane components run as static pods on the control-plane. Remove the bad flag; the kubelet restarts the pod.

```bash
docker exec -it kindlab-control-plane bash
grep -n bogus /etc/kubernetes/manifests/kube-scheduler.yaml
sed -i '/--bogus-flag=true/d' /etc/kubernetes/manifests/kube-scheduler.yaml
exit
kubectl -n kube-system get pod kube-scheduler-kindlab-control-plane -w
```

## Step 3 — Back up etcd
etcd runs as a static pod with `etcdctl` + certs inside. The image is distroless (no shell) — call `etcdctl` directly. Save under `/var/lib/etcd` (mounted on the node), then copy to `/opt`.

```bash
kubectl -n kube-system exec etcd-kindlab-control-plane -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /var/lib/etcd/snapshot.db

docker exec kindlab-control-plane cp /var/lib/etcd/snapshot.db /opt/snapshot.db
```

## Step 4 — Cordon and drain a node
```bash
kubectl cordon kindlab-worker2
kubectl drain kindlab-worker2 --ignore-daemonsets --delete-emptydir-data
```
`cordon` sets `spec.unschedulable=true` (no new pods). `drain` also evicts existing pods (skipping DaemonSets).

## Step 5 — Uncordon the node
```bash
kubectl uncordon kindlab-worker2
kubectl get node kindlab-worker2   # STATUS no longer shows SchedulingDisabled
```
Uncordon clears `spec.unschedulable` so the scheduler can place new pods there again. It does not move already-running pods back.
