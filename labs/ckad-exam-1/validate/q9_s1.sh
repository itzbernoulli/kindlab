#!/bin/bash
NS=exam
SVC=np-svc
TYPE=$(kubectl -n $NS get svc $SVC -o jsonpath='{.spec.type}' 2>/dev/null)
if [ -z "$TYPE" ]; then echo "❌ Service '$SVC' not found in namespace $NS"; exit 1; fi
if [ "$TYPE" != "NodePort" ]; then echo "❌ Service '$SVC' type is $TYPE, expected NodePort"; exit 1; fi
SEL=$(kubectl -n $NS get svc $SVC -o jsonpath='{.spec.selector.app}' 2>/dev/null)
if [ "$SEL" != "np" ]; then echo "❌ Service selector must be app=np (got app='${SEL:-none}')"; exit 1; fi
NP=$(kubectl -n $NS get svc $SVC -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
if [ "$NP" != "30080" ]; then echo "❌ nodePort must be 30080 (got '${NP:-none}')"; exit 1; fi
EP=$(kubectl -n $NS get endpoints $SVC -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
if [ -z "$EP" ]; then echo "❌ Service '$SVC' has no ready endpoints"; exit 1; fi
echo "✅ Service 'np-svc' is NodePort on 30080 selecting app=np with endpoints"; exit 0
