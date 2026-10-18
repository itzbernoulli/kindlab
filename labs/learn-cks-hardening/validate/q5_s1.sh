#!/bin/bash
POD="kube-apiserver-$CP"
# Read the RUNNING apiserver command. --profiling must be present AND equal to false.
FLAG=$(kubectl -n kube-system get pod "$POD" -o jsonpath='{.spec.containers[0].command}' 2>/dev/null \
  | tr ',' '\n' | grep -- '--profiling' | head -n1)
if [ -z "$FLAG" ]; then
  echo "❌ --profiling flag not present on running $POD (apiserver down, or flag absent -> defaults to true). Add --profiling=false in /etc/kubernetes/manifests/kube-apiserver.yaml on $CP"; exit 1
fi
VAL=$(echo "$FLAG" | sed 's/.*--profiling=//; s/[^a-zA-Z].*//')
if [ "$VAL" = "false" ]; then
  echo "✅ running kube-apiserver has --profiling=false"; exit 0
fi
echo "❌ --profiling is '${VAL}' on $CP (expected false). Set --profiling=false."; exit 1
