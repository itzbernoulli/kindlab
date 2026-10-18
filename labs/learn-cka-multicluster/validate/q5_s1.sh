#!/bin/bash
# Read the kubeconfig entry for the kind-kindlab2 context and check its default namespace.
NS=$(kubectl config view -o jsonpath="{.contexts[?(@.name==\"$CTX2\")].context.namespace}" 2>/dev/null)
if [ "$NS" = "prod" ]; then echo "✅ context $CTX2 default namespace == prod"; exit 0; fi
echo "❌ set the default namespace of context $CTX2 to prod: kubectl config set-context $CTX2 --namespace=prod (current: '${NS:-<none>}')"; exit 1
