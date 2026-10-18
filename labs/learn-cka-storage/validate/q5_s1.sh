#!/bin/bash
D=$(kubectl get sc fast-local -o jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}' 2>/dev/null)
if [ -z "$(kubectl get sc fast-local -o name 2>/dev/null)" ]; then
  echo "❌ StorageClass 'fast-local' not found."; exit 1
fi
if [ "$D" != "true" ]; then
  echo "❌ fast-local is not marked default (annotation='${D:-none}'). Set is-default-class to \"true\"."; exit 1
fi
echo "✅ StorageClass fast-local is marked default"; exit 0
