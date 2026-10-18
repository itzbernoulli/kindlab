#!/bin/bash
P=$(kubectl get sc fast-local -o jsonpath='{.provisioner}' 2>/dev/null)
M=$(kubectl get sc fast-local -o jsonpath='{.volumeBindingMode}' 2>/dev/null)
if [ -z "$P" ]; then
  echo "❌ StorageClass 'fast-local' not found. Create it with provisioner rancher.io/local-path."; exit 1
fi
if [ "$P" != "rancher.io/local-path" ]; then
  echo "❌ fast-local provisioner is '$P', expected 'rancher.io/local-path'."; exit 1
fi
if [ "$M" != "WaitForFirstConsumer" ]; then
  echo "❌ fast-local volumeBindingMode is '${M:-Immediate}', expected 'WaitForFirstConsumer'."; exit 1
fi
echo "✅ StorageClass fast-local has provisioner rancher.io/local-path and WaitForFirstConsumer"; exit 0
