#!/bin/bash
if ! kubectl get pod dnscheck -n cni-learn >/dev/null 2>&1; then echo "❌ create pod 'dnscheck' that runs: nslookup kubernetes.default.svc.cluster.local"; exit 1; fi
LOG=$(kubectl logs dnscheck -n cni-learn 2>/dev/null)
if echo "$LOG" | grep -qiE "can't resolve|NXDOMAIN|server can't find"; then echo "❌ dnscheck DNS lookup failed. Use the FQDN kubernetes.default.svc.cluster.local"; exit 1; fi
if echo "$LOG" | grep -qi "kubernetes.default.svc.cluster.local" && echo "$LOG" | grep -qi "Address"; then echo "✅ dnscheck resolved kubernetes.default.svc.cluster.local via CoreDNS"; exit 0; fi
echo "❌ dnscheck logs don't show a successful lookup yet. Run: nslookup kubernetes.default.svc.cluster.local"; exit 1
