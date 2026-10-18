#!/bin/bash
kubectl -n workloads-learn get job stuck >/dev/null 2>&1 || { echo "❌ Job 'stuck' not found (don't delete it — fix its parallelism)"; exit 1; }
S=$(kubectl -n workloads-learn get job stuck -o jsonpath='{.status.succeeded}' 2>/dev/null)
[ "${S:-0}" -ge 3 ] 2>/dev/null || { echo "❌ Job stuck has ${S:-0}/3 successes — it's paused at parallelism:0. Patch spec.parallelism up"; exit 1; }
echo "✅ Job stuck completed (${S}/3) — parallelism fixed"; exit 0
