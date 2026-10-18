#!/bin/bash
# Step 4: a NEW bootstrap-token Secret must exist in kube-system (count strictly up
# from what q4_setup.sh recorded).
ORIG=$(cat "$LAB_DIR/.tokens.orig" 2>/dev/null); ORIG=${ORIG:-0}
N=$(kubectl -n kube-system get secrets --field-selector type=bootstrap.kubernetes.io/token --no-headers 2>/dev/null | grep -c .)
if [ "${N:-0}" -gt "$ORIG" ]; then
  echo "✅ a new join token was created ($N bootstrap-token Secrets now, was $ORIG)"; exit 0
fi
echo "❌ no new join token yet ($N now, was $ORIG). Create one: docker exec \"\$CP\" kubeadm token create --print-join-command"; exit 1
