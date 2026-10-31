# Node toolbox

When `kubectl` isn't enough — the apiserver is down, the kubelet won't start, a
static pod crash-loops before it registers — you drop to the node and use the
runtime/systemd tools directly. This is the reference the in-app **🧰 Node
toolbox** panel mirrors (see `web/app.js` → `nodeToolbox()`). Keep the two in sync.

## Get on a node

```bash
docker exec -it $CP bash      # exam equivalent: ssh <node>  then  sudo -i
```

Nodes: `$CP` control-plane, `$W1` / `$W2` workers. kind nodes have **no vi/nano** —
edit with `sed -i`, or `apt-get update && apt-get install -y vim`.

## Key paths (on the node)

| What | Where |
|------|-------|
| Static-pod manifests (apiserver, etcd, scheduler, controller-manager) | `/etc/kubernetes/manifests/` |
| Component kubeconfigs | `/etc/kubernetes/{admin,kubelet,controller-manager,scheduler}.conf` |
| Certs / PKI | `/etc/kubernetes/pki/` (`ca.crt`, `apiserver*`, `etcd/`) |
| etcd data dir | `/var/lib/etcd` |
| Kubelet config | `/var/lib/kubelet/config.yaml` |
| Kubelet systemd drop-ins | `/etc/systemd/system/kubelet.service.d/` |
| CNI config / plugins | `/etc/cni/net.d/` · `/opt/cni/bin` |
| Pod & container logs | `/var/log/pods` · `/var/log/containers` |
| containerd | `/etc/containerd/config.toml` · socket `/run/containerd/containerd.sock` |

## crictl — containers when the API / kubectl is down

```bash
crictl ps -a                 # every container, including exited (crash-loops)
crictl logs <container-id>   # stdout/stderr of a container
crictl pods                  # pod sandboxes
crictl inspect <id>          # full container/pod detail
```

The runtime endpoint is preconfigured on kind (`/etc/crictl.yaml`). Elsewhere:
`crictl --runtime-endpoint unix:///run/containerd/containerd.sock ps -a`.

Use crictl when a control-plane static pod never becomes Ready: `kubectl` can't
show you logs for a container the apiserver never heard about.

## kubelet — systemd & logs

```bash
systemctl status kubelet                    # running? crash-looping?
journalctl -u kubelet -e --no-pager         # WHY it won't start (config/cert errors)
systemctl daemon-reload && systemctl restart kubelet   # after editing config or the unit
```

Typical faults: a bad value in `/var/lib/kubelet/config.yaml`, a broken drop-in
under `/etc/systemd/system/kubelet.service.d/`, or expired/missing certs.

## etcd & certs

```bash
# talk to etcd with the apiserver's client certs
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/apiserver-etcd-client.crt \
  --key=/etc/kubernetes/pki/apiserver-etcd-client.key \
  member list

etcdctl ... snapshot save /var/lib/etcd/snap.db      # back up
etcdutl snapshot restore /var/lib/etcd/snap.db ...   # restore (offline)
```

```bash
kubeadm certs check-expiration                       # cert expiry at a glance
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text -dates
kubeadm token list                                   # join tokens
kubeadm upgrade plan                                 # what an upgrade would do
```
