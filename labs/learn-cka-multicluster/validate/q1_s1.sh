#!/bin/bash
ON2=$(kubectl --context "$CTX2" get ns prod -o name 2>/dev/null)
ON1=$(kubectl --context "$CTX" get ns prod -o name 2>/dev/null)
if [ -n "$ON2" ] && [ -z "$ON1" ]; then echo "✅ namespace 'prod' exists on cluster2 ($CTX2) only"; exit 0; fi
if [ -z "$ON2" ]; then echo "❌ create 'prod' on cluster2: kubectl config use-context $CTX2 && kubectl create ns prod"; exit 1; fi
echo "❌ 'prod' also exists on cluster1 — it should be on cluster2 ($CTX2) only. Wrong context."; exit 1
