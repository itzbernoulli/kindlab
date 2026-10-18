#!/bin/bash
POD="kube-apiserver-$CP"
# Read the RUNNING apiserver pod spec. If the candidate broke the manifest, kubectl
# cannot reach the apiserver and this fails with an actionable reason.
PLUGINS=$(kubectl -n kube-system get pod "$POD" -o yaml 2>/dev/null \
  | grep -- '--enable-admission-plugins' | head -n1)
if [ -z "$PLUGINS" ]; then
  echo "❌ could not read $POD (apiserver down? no --enable-admission-plugins flag?). Add NodeRestriction to --enable-admission-plugins in /etc/kubernetes/manifests/kube-apiserver.yaml on $CP"; exit 1
fi
if echo "$PLUGINS" | grep -q 'NodeRestriction'; then
  echo "✅ running kube-apiserver has NodeRestriction in --enable-admission-plugins"; exit 0
fi
echo "❌ --enable-admission-plugins does not include NodeRestriction (found:${PLUGINS}). Add it on $CP."; exit 1
