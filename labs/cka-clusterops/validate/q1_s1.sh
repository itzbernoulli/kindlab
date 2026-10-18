#!/bin/bash
if docker exec "$W1" sh -c 'grep -rlq "name: static-web" /etc/kubernetes/manifests/ 2>/dev/null'; then
  echo "✅ static pod manifest (name: static-web) present on $W1"; exit 0
fi
echo "❌ no static pod manifest naming 'static-web' in /etc/kubernetes/manifests/ on $W1"; exit 1
