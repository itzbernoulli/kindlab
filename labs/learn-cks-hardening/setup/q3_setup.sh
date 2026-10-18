#!/bin/bash
# Seed an INSECURE kubelet on $W2 so the learner must lock down authn/authz:
#   authentication.anonymous.enabled: true  (want false)
#   authorization.mode: AlwaysAllow          (want Webhook)
# kind/kubeadm ships these secure by default, so we flip them here (block-aware awk,
# so we only touch 'enabled:' inside the anonymous: block, not webhook's).
# Breaking only a worker kubelet config is recoverable — never the apiserver/etcd.
C=/var/lib/kubelet/config.yaml
docker exec "$W2" sh -c "
  awk '
    /^authentication:/ {sec=\"authn\"}
    /^authorization:/  {sec=\"authz\"}
    /^[^[:space:]]/ && !/^authentication:/ && !/^authorization:/ {sec=\"\"}
    sec==\"authn\" && /^[[:space:]]+anonymous:/ {inanon=1}
    sec==\"authn\" && inanon==1 && /^[[:space:]]+enabled:/ {sub(/enabled:.*/,\"enabled: true\"); inanon=0}
    sec==\"authn\" && /^[[:space:]]+webhook:/ {inanon=0}
    sec==\"authz\" && /^[[:space:]]+mode:/ {sub(/mode:.*/,\"mode: AlwaysAllow\")}
    {print}
  ' $C > ${C}.tmp && mv ${C}.tmp $C
  # If the config somehow lacked an anonymous block, force the insecure value in.
  grep -q 'mode: AlwaysAllow' $C || sed -i 's/^\(\s*mode:\).*/\1 AlwaysAllow/' $C
  systemctl restart kubelet
"
echo "seeded insecure kubelet on $W2 (anonymous.enabled: true, authorization.mode: AlwaysAllow) — lock it down"
