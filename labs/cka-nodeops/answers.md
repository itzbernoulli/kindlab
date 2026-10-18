# CKA Node & Component Troubleshooting — Answers

> Node names come from `kindlab up`: `kindlab-control-plane`, `kindlab-worker`, `kindlab-worker2`.
> Get a node shell with `docker exec -it <node> bash`. `kubectl` uses the kindlab context automatically (`export KUBECONFIG=kindlab/.state/kubeconfig`).

## Task 1 — Recover a NotReady node
The node is NotReady because its kubelet is stopped. The kubelet runs as a systemd service inside the node container; restart it.

```bash
kubectl get nodes                               # kindlab-worker is NotReady
docker exec -it kindlab-worker bash
systemctl status kubelet                        # inactive (dead)
systemctl start kubelet
systemctl is-active kubelet                     # active
exit

# node returns to Ready within ~15s
kubectl get node kindlab-worker -w
```
Troubleshooting a NotReady node: check kubelet with `systemctl status kubelet` and `journalctl -u kubelet -n 50` on the node.

## Task 2 — Repair the kube-controller-manager
Control-plane components (apiserver, scheduler, controller-manager, etcd) run as **static pods** from `/etc/kubernetes/manifests/` on the control-plane. A bad flag makes the pod crash-loop; remove it and the kubelet restarts it automatically.

```bash
kubectl -n kube-system get pods | grep controller-manager   # CrashLoopBackOff / not Ready
docker exec -it kindlab-control-plane bash
grep -n bogus /etc/kubernetes/manifests/kube-controller-manager.yaml   # find the bad line
sed -i '/--bogus-flag=true/d' /etc/kubernetes/manifests/kube-controller-manager.yaml
exit

# kubelet recreates the static pod within ~15s
kubectl -n kube-system get pod kube-controller-manager-kindlab-control-plane -w
```
Alternative troubleshooting: on the node use `crictl ps -a` + `crictl logs <id>`, or `kubectl -n kube-system describe pod kube-controller-manager-...`.

## Task 3 — Uncordon a node
Cordon sets `spec.unschedulable=true`; uncordon clears it so the scheduler can place pods there again.

```bash
kubectl get node kindlab-worker                 # SchedulingDisabled
kubectl uncordon kindlab-worker
kubectl get node kindlab-worker                 # Ready (no SchedulingDisabled)
```

## Task 4 — Static pod on the control-plane
A static pod is created by the kubelet directly from a manifest in `/etc/kubernetes/manifests/` on a node (no API server involved). The API server shows a read-only **mirror pod** named `<pod-name>-<node-name>`.

```bash
docker exec -it kindlab-control-plane bash
cat >/etc/kubernetes/manifests/cp-web.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: cp-web
spec:
  containers:
  - name: web
    image: nginx:alpine
EOF
exit

# mirror pod appears as cp-web-kindlab-control-plane
kubectl get pod cp-web-kindlab-control-plane -n default
```

## Task 5 — Drain a node
`drain` cordons the node first (so no new pods land there), then evicts the existing pods. The `draintest` Deployment reschedules the evicted replicas onto the remaining nodes. `--ignore-daemonsets` skips DaemonSet-managed pods (which can't be rescheduled).

```bash
kubectl get pods -o wide -l app=draintest       # see which run on kindlab-worker2
kubectl drain kindlab-worker2 --ignore-daemonsets --delete-emptydir-data

kubectl get node kindlab-worker2                 # SchedulingDisabled (unschedulable=true)
kubectl get pods -o wide -l app=draintest        # none on kindlab-worker2; rescheduled elsewhere

# bring it back after maintenance:
kubectl uncordon kindlab-worker2
```

## Task 6 — Taint a node and schedule a tolerating pod
A `NoSchedule` taint repels pods that don't tolerate it. Add the taint, then give the `batch` pod a matching toleration and pin it to the node.

```bash
kubectl taint nodes kindlab-worker workload=batch:NoSchedule

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: batch
  namespace: default
spec:
  nodeName: kindlab-worker
  tolerations:
  - key: workload
    operator: Equal
    value: batch
    effect: NoSchedule
  containers:
  - name: c
    image: busybox:1.36
    command: ["sh", "-c", "sleep 3600"]
EOF

kubectl get pod batch -o wide                    # Running on kindlab-worker
```
Using `nodeName: kindlab-worker` pins the pod directly. You could instead add a label to the node and use a `nodeSelector`. Remove the taint later with `kubectl taint nodes kindlab-worker workload=batch:NoSchedule-`.
