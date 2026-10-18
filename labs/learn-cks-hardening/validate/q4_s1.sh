#!/bin/bash
POD="kube-apiserver-$CP"
# Read the RUNNING apiserver pod spec. If the manifest was broken, kubectl cannot
# reach the apiserver and this fails with an actionable reason.
PLUGINS=$(kubectl -n kube-system get pod "$POD" -o jsonpath='{.spec.containers[0].command}' 2>/dev/null \
  | tr ',' '\n' | grep -- '--enable-admission-plugins' | head -n1)
if [ -z "$PLUGINS" ]; then
  echo "❌ could not find --enable-admission-plugins on running $POD (apiserver down? flag missing?). Add NodeRestriction to --enable-admission-plugins in /etc/kubernetes/manifests/kube-apiserver.yaml on $CP"; exit 1
fi
# Extract the comma-separated value and check NodeRestriction is one of the plugins.
VAL=${PLUGINS#*=}
if echo ",$VAL," | grep -q ',NodeRestriction,'; then
  echo "✅ running kube-apiserver has NodeRestriction in --enable-admission-plugins"; exit 0
fi
echo "❌ --enable-admission-plugins does not include NodeRestriction (value: '${VAL}'). Add it on $CP."; exit 1
