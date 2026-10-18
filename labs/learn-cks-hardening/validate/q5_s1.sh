#!/bin/bash
NS=cks-learn
# 1) SA no-token must have automountServiceAccountToken: false
AM=$(kubectl -n "$NS" get serviceaccount no-token -o jsonpath='{.automountServiceAccountToken}' 2>/dev/null)
if [ -z "$AM" ]; then
  echo "❌ ServiceAccount 'no-token' not found (or automount field unset) in $NS. Create it with automountServiceAccountToken: false."; exit 1
fi
if [ "$AM" != "false" ]; then
  echo "❌ ServiceAccount 'no-token' has automountServiceAccountToken='$AM' (want false)."; exit 1
fi
# 2) Pod hardened must exist and use the no-token SA
PSA=$(kubectl -n "$NS" get pod hardened -o jsonpath='{.spec.serviceAccountName}' 2>/dev/null)
if [ -z "$PSA" ]; then
  echo "❌ Pod 'hardened' not found in $NS. Create it (image busybox:1.36) with serviceAccountName: no-token."; exit 1
fi
if [ "$PSA" != "no-token" ]; then
  echo "❌ Pod 'hardened' uses serviceAccount '$PSA' (want no-token)."; exit 1
fi
# 3) No ServiceAccount token volume should be mounted into the pod.
MOUNTS=$(kubectl -n "$NS" get pod hardened -o jsonpath='{.spec.containers[*].volumeMounts[*].mountPath}' 2>/dev/null)
if echo "$MOUNTS" | grep -q '/var/run/secrets/kubernetes.io/serviceaccount'; then
  echo "❌ Pod 'hardened' still mounts a ServiceAccount token. Ensure automount is disabled (SA or pod spec)."; exit 1
fi
echo "✅ SA 'no-token' has automount disabled and pod 'hardened' uses it with no token mounted"; exit 0
