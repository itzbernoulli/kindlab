#!/bin/bash
g(){ kubectl -n labels-learn get pod "$1" -o jsonpath='{.metadata.labels.canary}' 2>/dev/null; }
[ "$(g rel-beta)" = "yes" ] || { echo "❌ rel-beta must have canary=yes"; exit 1; }
[ "$(g rel-rc)" = "yes" ] || { echo "❌ rel-rc must have canary=yes"; exit 1; }
[ -z "$(g rel-stable)" ] || { echo "❌ rel-stable must NOT have canary (set-based selector should exclude it)"; exit 1; }
echo "✅ canary=yes on beta+rc only (stable excluded)"; exit 0
