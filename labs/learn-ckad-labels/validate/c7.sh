#!/bin/bash
kubectl -n labels-learn get svc shop-svc >/dev/null 2>&1 || { echo "❌ Service 'shop-svc' not found (don't delete it — fix the selector)"; exit 1; }
IP=$(kubectl -n labels-learn get endpoints shop-svc -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
[ -n "$IP" ] || { echo "❌ shop-svc still has no endpoints — its selector (app=shop,tier=cache) matches no pod. Remove tier (set tier:null)"; exit 1; }
echo "✅ shop-svc now has endpoints ($IP)"; exit 0
