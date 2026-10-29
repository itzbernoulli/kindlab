#!/bin/bash
ON2=$(kubectl --context "$CTX2" get ns prod -o name 2>/dev/null)
ON1=$(kubectl --context "$CTX" get ns prod -o name 2>/dev/null)
if [ -z "$ON2" ]; then echo "❌ namespace 'prod' not found on cluster2 ($CTX2): kubectl config use-context $CTX2 && kubectl create ns prod"; exit 1; fi
if [ -n "$ON1" ]; then echo "❌ 'prod' also exists on cluster1 ($CTX) — it must be on cluster2 only. Wrong context."; exit 1; fi
echo "✅ namespace 'prod' exists on cluster2 ($CTX2) only"
