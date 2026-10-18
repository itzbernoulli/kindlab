#!/bin/bash
if ! kubectl get pod client -n cni-learn >/dev/null 2>&1; then echo "❌ create pod 'client' that does: wget -qO- http://web.cni-learn"; exit 1; fi
LOG=$(kubectl logs client -n cni-learn 2>/dev/null)
if echo "$LOG" | grep -qiE "welcome to nginx|<title>"; then echo "✅ client reached the web Service (CNI + kube-proxy datapath works)"; exit 0; fi
echo "❌ client didn't get a response from http://web.cni-learn — check the Service endpoints and CNI"; exit 1
