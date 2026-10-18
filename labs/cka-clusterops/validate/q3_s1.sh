#!/bin/bash
S=$(kubectl get csr developer -o jsonpath='{.status.conditions[?(@.type=="Approved")].status}' 2>/dev/null)
if [ "$S" = "True" ]; then echo "✅ CSR 'developer' is Approved"; exit 0; fi
echo "❌ CSR 'developer' not approved (status='${S:-none}'). Run: kubectl certificate approve developer"; exit 1
