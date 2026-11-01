#!/bin/bash
# Disaster-recovery scenario on THIS lab's throwaway cluster (the harness
# provisions 'kindlab-etcd' fresh at Start — never the main cluster).
# Seed a 'canary', snapshot it (the "backup taken earlier"), then DELETE it so
# the learner must restore the snapshot AND cut the live etcd over to recover it.
SCRATCH="${SCRATCH:-kindlab-etcd}"
NODE="${SCRATCH_NODE:-$SCRATCH-control-plane}"
KC="${SCRATCH_KUBECONFIG:-$(dirname "$KUBECONFIG")/$SCRATCH.kubeconfig}"
k(){ kubectl --kubeconfig "$KC" "$@"; }

# wait for the scratch API server to answer
for i in $(seq 1 45); do k get ns >/dev/null 2>&1 && break; sleep 2; done

# belt-and-suspenders reset (cluster is fresh, but make re-runs safe)
docker exec "$NODE" rm -rf /var/lib/etcd/snap.db /var/lib/etcd/restored >/dev/null 2>&1
docker exec "$NODE" sed -i -E 's#^([[:space:]]*path:[[:space:]]*)/var/lib/etcd/restored$#\1/var/lib/etcd#' /etc/kubernetes/manifests/etcd.yaml >/dev/null 2>&1

# 1) seed the canary we will recover
k get ns canary >/dev/null 2>&1 || k create ns canary >/dev/null 2>&1
k -n canary delete configmap canary --ignore-not-found >/dev/null 2>&1
k -n canary create configmap canary --from-literal=marker=keepme >/dev/null 2>&1

# 2) take the "earlier" snapshot (contains the canary) — distroless etcd: call etcdctl directly
POD=$(k -n kube-system get pod -l component=etcd -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
CA=/etc/kubernetes/pki/etcd/ca.crt; CRT=/etc/kubernetes/pki/etcd/server.crt; KEY=/etc/kubernetes/pki/etcd/server.key
for i in $(seq 1 15); do
  k -n kube-system exec "$POD" -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=$CA --cert=$CRT --key=$KEY snapshot save /var/lib/etcd/snap.db >/dev/null 2>&1 && break
  sleep 2
done

# 3) DISASTER: lose the canary
k delete ns canary --wait=true >/dev/null 2>&1

echo "etcd DR scenario ready on '$SCRATCH': snapshot at /var/lib/etcd/snap.db, canary LOST. Target kubectl at: $KC"
