#!/bin/bash
# Read the RUNNING kube-apiserver pod spec for the audit flags.
# If the candidate broke the manifest, kubectl returns nothing and this fails with a clear reason.
POD="kube-apiserver-$CP"
CMD=$(kubectl -n kube-system get pod "$POD" -o jsonpath='{.spec.containers[0].command}' 2>/dev/null)
if [ -z "$CMD" ]; then
  echo "❌ kube-apiserver pod '$POD' not found/running — check your manifest edit (/etc/kubernetes/manifests/kube-apiserver.yaml) for YAML or flag errors"; exit 1
fi
if echo "$CMD" | grep -q -- '--audit-policy-file=/etc/kubernetes/audit-policy.yaml' && echo "$CMD" | grep -q -- '--audit-log-path=/var/log/kubernetes/audit.log'; then
  echo "✅ running kube-apiserver has --audit-policy-file and --audit-log-path"; exit 0
fi
echo "❌ kube-apiserver missing audit flags (need --audit-policy-file=/etc/kubernetes/audit-policy.yaml and --audit-log-path=/var/log/kubernetes/audit.log)"; exit 1
