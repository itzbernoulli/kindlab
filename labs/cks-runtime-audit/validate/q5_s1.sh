#!/bin/bash
# Running kube-apiserver must carry the encryption-provider-config flag.
POD="kube-apiserver-$CP"
CMD=$(kubectl -n kube-system get pod "$POD" -o jsonpath='{.spec.containers[0].command}' 2>/dev/null)
if [ -z "$CMD" ]; then
  echo "❌ kube-apiserver pod '$POD' not found/running — check your manifest edit for YAML or flag errors"; exit 1
fi
if echo "$CMD" | grep -q -- '--encryption-provider-config=/etc/kubernetes/enc/enc.yaml'; then
  echo "✅ running kube-apiserver has --encryption-provider-config=/etc/kubernetes/enc/enc.yaml"; exit 0
fi
echo "❌ kube-apiserver missing --encryption-provider-config=/etc/kubernetes/enc/enc.yaml (also mount /etc/kubernetes/enc as a hostPath volume)"; exit 1
