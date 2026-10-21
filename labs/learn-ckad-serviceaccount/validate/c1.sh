#!/bin/bash
kubectl -n sa-learn get sa deployer >/dev/null 2>&1 && { echo "✅ ServiceAccount deployer exists"; exit 0; }
echo "❌ ServiceAccount 'deployer' not found — kubectl -n sa-learn create serviceaccount deployer"; exit 1
