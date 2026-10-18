#!/bin/bash
CUR=$(kubectl config current-context 2>/dev/null)
if [ "$CUR" = "$CTX" ]; then echo "✅ active context is cluster1 ($CTX)"; exit 0; fi
echo "❌ set your active context to cluster1: kubectl config use-context $CTX  (current: ${CUR:-none})"; exit 1
