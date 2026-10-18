#!/bin/bash
NS=modify-learn
R=$(kubectl -n $NS get deploy widget -o jsonpath='{.spec.replicas}' 2>/dev/null)
IMG=$(kubectl -n $NS get deploy widget -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
AVL=$(kubectl -n $NS get deploy widget -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ -z "$R" ]; then echo "❌ deployment 'widget' not found in $NS"; exit 1; fi
if [ "$R" != "3" ]; then echo "❌ widget replicas is '${R}', expected 3. Edit /tmp/kindlab-assets/widget-deploy.yaml and kubectl apply -f it"; exit 1; fi
if [ "$IMG" != "nginx:1.26" ]; then echo "❌ widget image is '${IMG}', expected 'nginx:1.26'. Update the manifest file and re-apply"; exit 1; fi
if [ "${AVL:-0}" -lt 3 ]; then echo "❌ widget not fully available yet (${AVL:-0}/3)"; exit 1; fi
echo "✅ widget updated to replicas=3, image nginx:1.26 (edited the on-disk manifest and re-applied)"; exit 0
