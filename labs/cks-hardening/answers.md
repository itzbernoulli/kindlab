# CKS Kubelet, File & RBAC Hardening — Answers

> Node names come from `kindlab up`: `kindlab-control-plane` (`$CP`), `kindlab-worker` (`$W1`), `kindlab-worker2` (`$W2`).
> Get a node shell with `docker exec -it <node> bash`. `kubectl` uses the kindlab context automatically (`export KUBECONFIG=kindlab/.state/kubeconfig`).

## Task 1 — Harden a static pod manifest's file permissions
Control-plane static pod manifests under `/etc/kubernetes/manifests/` should be `root:root` mode `0600` (CIS 1.1.x). Changing a manifest's mode does not restart the pod.

```bash
docker exec kindlab-control-plane chmod 600 /etc/kubernetes/manifests/kube-scheduler.yaml

# verify
docker exec kindlab-control-plane stat -c '%a %U:%G' /etc/kubernetes/manifests/kube-scheduler.yaml
# -> 600 root:root
```

## Task 2 — Disable the kubelet read-only port
The read-only port (`10255`) serves unauthenticated kubelet data and must be `0`. Edit the kubelet config on the worker and restart the kubelet.

```bash
docker exec -it kindlab-worker bash
# set readOnlyPort to 0 (edit in place)
sed -i 's/^readOnlyPort:.*/readOnlyPort: 0/' /var/lib/kubelet/config.yaml
grep readOnlyPort /var/lib/kubelet/config.yaml      # readOnlyPort: 0
systemctl restart kubelet
exit

# give it ~20s, then confirm the node is Ready again
kubectl get node kindlab-worker
```
If `readOnlyPort` is absent, add the line `readOnlyPort: 0` to `/var/lib/kubelet/config.yaml`.

## Task 3 — Enable the NodeRestriction admission plugin
`NodeRestriction` limits what a kubelet can modify via the API (only its own Node/Pods). Add it to `--enable-admission-plugins` on the apiserver static pod. The kubelet restarts the apiserver automatically after you save.

```bash
docker exec -it kindlab-control-plane bash
vi /etc/kubernetes/manifests/kube-apiserver.yaml
exit
```
Find the `--enable-admission-plugins` line and append `,NodeRestriction` to the existing value, e.g.:
```yaml
    - --enable-admission-plugins=NodeRestriction
```
or if other plugins are present keep them: `--enable-admission-plugins=NamespaceLifecycle,...,NodeRestriction`.
If the flag does not exist, add it as a new line under the `kube-apiserver` command args.

```bash
# apiserver will restart; wait ~30-60s, then confirm the flag is live
kubectl -n kube-system get pod kube-apiserver-kindlab-control-plane -o yaml | grep enable-admission-plugins
```
Edit carefully — a YAML/typo error here takes the apiserver down (`kubectl` stops responding). If that happens, fix the manifest on the node and the kubelet restarts it.

## Task 4 — Least-privilege RBAC for the `reader` ServiceAccount
Grant only `get`/`list` on pods in `rbac-lab`, bound to the `reader` SA.

```bash
kubectl -n rbac-lab create role pod-reader \
  --verb=get,list --resource=pods

kubectl -n rbac-lab create rolebinding reader-binding \
  --role=pod-reader \
  --serviceaccount=rbac-lab:reader

# verify least privilege
kubectl auth can-i list   pods --as=system:serviceaccount:rbac-lab:reader -n rbac-lab   # yes
kubectl auth can-i delete pods --as=system:serviceaccount:rbac-lab:reader -n rbac-lab   # no
```

## Task 5 — Enforce the restricted Pod Security Standard
Label the namespace so Pod Security Admission enforces the `restricted` profile, pinned to `v1.29`.

```bash
kubectl label ns restricted-ns \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/enforce-version=v1.29 \
  --overwrite

# verify
kubectl get ns restricted-ns --show-labels
```
After this, pods that violate the restricted profile (e.g. running as root, privileged, hostPath) are rejected at admission in `restricted-ns`.

## Task 6 — Default-deny NetworkPolicy
A policy with an empty `podSelector` selecting all pods and both `Ingress` + `Egress` policy types (with no allow rules) denies all traffic in the namespace.

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: netpol-lab
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# verify
kubectl -n netpol-lab get networkpolicy default-deny -o yaml
```
`podSelector: {}` matches every pod in the namespace; listing both policy types with no `ingress`/`egress` rules means nothing is allowed in or out. (Note: kind's default CNI, kindnet, does not enforce NetworkPolicy, but the object is still valid and graded here; on a Calico/Cilium cluster the deny would take effect.)
