#!/bin/bash
NS=exam
IMG=$(kubectl -n $NS get deploy web -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
LBL=$(kubectl -n $NS get deploy web -o jsonpath='{.spec.template.metadata.labels.app}' 2>/dev/null)
if [ -z "$IMG" ]; then echo "❌ Deployment 'web' not found in namespace $NS"; exit 1; fi
if [ "$IMG" != "nginx:1.25" ]; then echo "❌ Deployment 'web' image is '$IMG', expected nginx:1.25"; exit 1; fi
if [ "$LBL" != "web" ]; then echo "❌ pod template label app=web missing (got app='${LBL:-none}')"; exit 1; fi
echo "✅ Deployment 'web' uses nginx:1.25 with pod label app=web"; exit 0
