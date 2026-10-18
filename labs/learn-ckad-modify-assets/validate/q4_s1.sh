#!/bin/bash
NS=modify-learn
CM=$(kubectl -n $NS get configmap web-config -o jsonpath='{.data.COLOR}' 2>/dev/null)
if [ "$CM" != "green" ]; then echo "❌ ConfigMap web-config COLOR is '${CM:-unset}', expected 'green'. Update it (kubectl create cm web-config --from-literal=COLOR=green --dry-run=client -o yaml | kubectl apply -f -)"; exit 1; fi
POD=$(kubectl -n $NS get pods -l app=web --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$POD" ]; then echo "❌ no running web pods found"; exit 1; fi
SEEN=$(kubectl -n $NS exec "$POD" -- printenv COLOR 2>/dev/null | tr -d '\r')
if [ "$SEEN" != "green" ]; then echo "❌ web pod '$POD' still serves COLOR='${SEEN:-unset}' — editing the ConfigMap doesn't update running pods. Roll them: kubectl -n $NS rollout restart deployment/web"; exit 1; fi
echo "✅ web-config=green AND running web pods serve COLOR=green (a rollout restart was required — env is read once at pod start)"; exit 0
