#!/bin/bash
N=$(kubectl -n kube-system get secrets --field-selector type=bootstrap.kubernetes.io/token --no-headers 2>/dev/null | grep -c .)
echo "${N:-0}" > "$LAB_DIR/.tokens.orig" 2>/dev/null
echo "recorded ${N:-0} existing bootstrap token(s)"
