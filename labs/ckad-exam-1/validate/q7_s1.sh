#!/bin/bash
NS=exam
P=probed
READY=$(kubectl -n $NS get pod $P -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)
if [ -z "$READY" ]; then echo "❌ pod '$P' not found in namespace $NS"; exit 1; fi
LP=$(kubectl -n $NS get pod $P -o jsonpath='{.spec.containers[0].livenessProbe.httpGet.port}' 2>/dev/null)
RP=$(kubectl -n $NS get pod $P -o jsonpath='{.spec.containers[0].readinessProbe.httpGet.port}' 2>/dev/null)
if [ -z "$LP" ]; then echo "❌ liveness probe (httpGet) missing"; exit 1; fi
if [ -z "$RP" ]; then echo "❌ readiness probe (httpGet) missing"; exit 1; fi
if [ "$LP" != "80" ] || [ "$RP" != "80" ]; then echo "❌ probes must httpGet on port 80 (liveness=$LP readiness=$RP)"; exit 1; fi
if [ "$READY" != "true" ]; then echo "❌ pod '$P' is not Ready (ready=$READY)"; exit 1; fi
echo "✅ pod 'probed' has HTTP liveness+readiness on port 80 and is Ready"; exit 0
