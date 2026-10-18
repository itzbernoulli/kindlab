#!/bin/bash
S=$(kubectl get csr learn-dev -o jsonpath='{.status.conditions[?(@.type=="Approved")].status}' 2>/dev/null)
[ "$S" = "True" ] && { echo "✅ CSR 'learn-dev' is Approved"; exit 0; }
echo "❌ CSR 'learn-dev' not approved (status='${S:-none}'). Run: kubectl certificate approve learn-dev"; exit 1
