#!/bin/bash
NS=exam
SVC=clip-svc
TYPE=$(kubectl -n $NS get svc $SVC -o jsonpath='{.spec.type}' 2>/dev/null)
if [ -z "$TYPE" ]; then echo "❌ Service '$SVC' not found in namespace $NS"; exit 1; fi
if [ "$TYPE" != "ClusterIP" ]; then echo "❌ Service '$SVC' type is $TYPE, expected ClusterIP"; exit 1; fi
SEL=$(kubectl -n $NS get svc $SVC -o jsonpath='{.spec.selector.app}' 2>/dev/null)
if [ "$SEL" != "clip" ]; then echo "❌ Service selector must be app=clip (got app='${SEL:-none}')"; exit 1; fi
PORT=$(kubectl -n $NS get svc $SVC -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
if [ "$PORT" != "80" ]; then echo "❌ Service port must be 80 (got $PORT)"; exit 1; fi
EP=$(kubectl -n $NS get endpoints $SVC -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
if [ -z "$EP" ]; then echo "❌ Service '$SVC' has no ready endpoints (check selector matches running pods)"; exit 1; fi
echo "✅ Service 'clip-svc' is ClusterIP selecting app=clip with ready endpoints"; exit 0
